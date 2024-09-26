resource "helm_release" "cluster_autoscaler" {
  count      = var.cluster_created && var.autoscaling_type == "cluster-autoscaler" ? 1 : 0
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "cloudProvider"
    value = "aws"
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = var.autoscaler_service_name
  }

  values = [
    <<EOF
   extraArgs:
     skip-nodes-with-local-storage: "false"
   EOF
  ]
}

#create service account
resource "aws_iam_role" "role" {
  count = var.cluster_created && var.autoscaling_type == "cluster-autoscaler" ? 1 : 0
  name  = "${var.cluster_name}-${var.autoscaler_service_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer}"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "policy" {
  count = var.cluster_created && var.autoscaling_type == "cluster-autoscaler" ? 1 : 0
  name  = "${var.cluster_name}-${var.autoscaler_service_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeNodegroup",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeImages",
          "autoscaling:DescribeTags",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:SetDesiredCapacity"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attachment" {
  count      = var.cluster_created && var.autoscaling_type == "cluster-autoscaler" ? 1 : 0
  role       = aws_iam_role.role[0].name
  policy_arn = aws_iam_policy.policy[0].arn
}

resource "kubernetes_service_account" "this" {
  count = var.cluster_created && var.autoscaling_type == "cluster-autoscaler" ? 1 : 0
  metadata {
    name      = var.autoscaler_service_name
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.role[0].arn
    }
  }
  automount_service_account_token = true
}

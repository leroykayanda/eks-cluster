# Container insights helm chart

resource "helm_release" "insights" {
  count      = var.cluster_created && var.metrics_type == "cloudwatch" ? 1 : 0
  name       = var.container_insights_service_name
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = var.container_insights_service_name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  depends_on = [
    kubernetes_service_account.container_insights_sa
  ]
}

# Fluentbit helm chart

resource "helm_release" "fluent_bit" {
  count      = var.cluster_created && var.logs_type == "cloudwatch" ? 1 : 0
  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  namespace  = "kube-system"

  set {
    name  = "serviceAccount.name"
    value = var.container_insights_service_name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "cloudWatch.region"
    value = var.region
  }

  set {
    name  = "cloudWatchLogs.region"
    value = var.region
  }

  set {
    name  = "cloudWatch.logGroupName"
    value = "/aws/eks/${var.cluster_name}"
  }

  set {
    name  = "cloudWatchLogs.logGroupName"
    value = "/aws/eks/${var.cluster_name}"
  }

  set {
    name  = "cloudWatch.logRetentionDays"
    value = 30
  }

  set {
    name  = "cloudWatchLogs.logRetentionDays"
    value = 30
  }
}

# Create service account

resource "aws_iam_role" "container_insights_role" {
  count = var.cluster_created && var.metrics_type == "cloudwatch" ? 1 : 0
  name  = "${var.cluster_name}-${var.container_insights_service_name}"
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

resource "aws_iam_role_policy_attachment" "container_insights_attachment" {
  count      = var.cluster_created && var.metrics_type == "cloudwatch" ? 1 : 0
  role       = aws_iam_role.container_insights_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy" "policy_fluentbit" {
  count = var.cluster_created && var.logs_type == "cloudwatch" ? 1 : 0
  name  = "${var.env}-${var.container_insights_service_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:PutRetentionPolicy"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attachment_fluentbit" {
  count      = var.cluster_created && var.logs_type == "cloudwatch" ? 1 : 0
  role       = aws_iam_role.container_insights_role[0].name
  policy_arn = aws_iam_policy.policy_fluentbit[0].arn
}

resource "kubernetes_service_account" "container_insights_sa" {
  count = var.cluster_created && var.metrics_type == "cloudwatch" ? 1 : 0
  metadata {
    name      = var.container_insights_service_name
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.container_insights_role[0].arn
    }
  }
  automount_service_account_token = true
}

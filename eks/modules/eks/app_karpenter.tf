# Karpenter helm chart

resource "helm_release" "karpenter" {
  count      = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  namespace  = "kube-system"
  version    = "0.37.0"

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "settings.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter[0].name
  }

  set {
    name  = "serviceAccount.name"
    value = local.karpenter_sa
  }

  set {
    name  = "replicas"
    value = var.karpenter["replicas"]
  }

  values = [
    <<EOF
    controller:
      resources: 
        requests:
          cpu: "100m"
          memory: "256Mi"
        limits:
          cpu: "1000m"
          memory: "1Gi"
    tolerations:
    - key: "priority"
      operator: "Equal"
      value: "critical"
      effect: "NoSchedule"
    nodeSelector:
      priority: "critical"
    EOF
  ]

}

# Create service account

resource "aws_iam_role" "karpenter" {
  count = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0
  name  = "${var.cluster_name}-${local.karpenter_sa}"
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

resource "aws_iam_policy" "karpenter" {
  count  = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0
  name   = "${var.cluster_name}-${local.karpenter_sa}"
  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "ec2:CreateLaunchTemplate",
                "ec2:CreateFleet",
                "ec2:RunInstances",
                "ec2:CreateTags",
                "ec2:TerminateInstances",
                "ec2:DeleteLaunchTemplate",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeInstances",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeImages",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeInstanceTypeOfferings",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeSpotPriceHistory",
                "iam:PassRole",
                "ssm:GetParameter",
                "pricing:GetProducts",
                "iam:GetInstanceProfile"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "Karpenter"
        },
        {
            "Action": "ec2:TerminateInstances",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/Name": "*karpenter*"
                }
            },
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "ConditionalEC2Termination"
        },
        {
            "Effect": "Allow",
            "Action": "eks:DescribeCluster",
            "Resource": "${module.eks.cluster_arn}",
            "Sid": "eksClusterEndpointLookup"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_role_policy_attachment" "karpenter" {
  count      = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0
  role       = aws_iam_role.karpenter[0].name
  policy_arn = aws_iam_policy.karpenter[0].arn
}

resource "kubernetes_service_account" "karpenter" {
  count = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0
  metadata {
    name      = local.karpenter_sa
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter[0].arn
    }
  }
  automount_service_account_token = true
}

# Setting up a instance profile

resource "aws_iam_role" "karpenter_instance_profile_role" {
  count = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0
  name  = "karpenter-instance-profile-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          "Service" : "ec2.amazonaws.com"
        },
      }
    ]
  })
}

# Add karpenter role to EKS access entries to allow karpenter nodes to join cluster

resource "aws_eks_access_entry" "karpenter" {
  count         = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.karpenter_instance_profile_role[0].arn
  type          = "EC2_LINUX"
}

resource "aws_iam_instance_profile" "karpenter" {
  count = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0
  name  = "karpenter-instance-profile-${var.env}"
  role  = aws_iam_role.karpenter_instance_profile_role[0].name
}

resource "aws_iam_policy" "instance_profile_policy" {
  count       = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0
  name        = "instance-profile-karpenter-policy-${var.env}"
  description = "instance profile for karpenter policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeVpcs",
          "eks:DescribeCluster"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AssignPrivateIpAddresses",
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstanceTypes",
          "ec2:DetachNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:UnassignPrivateIpAddresses"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:network-interface/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "instance_profile" {
  count      = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0
  role       = aws_iam_role.karpenter_instance_profile_role[0].name
  policy_arn = aws_iam_policy.instance_profile_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "ebs" {
  count      = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0
  role       = aws_iam_role.karpenter_instance_profile_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "kubectl_manifest" "nodepools" {
  count = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0

  yaml_body = <<EOF
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: "karpenter"
spec:
  template:
    spec:
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: "karpenter"
      requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["on-demand"]
      - key: node.kubernetes.io/instance-type
        operator: In
        values: ${jsonencode(var.karpenter.instance_types)}
  limits:
    cpu: "${var.karpenter["cpu_limit"]}"
    memory: "${var.karpenter["memory_limit"]}"
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter:         "${var.karpenter["expire_after"]}"
    budgets:
    - nodes: "${var.karpenter["disruption_budget"]}"
EOF
}

resource "kubectl_manifest" "karpenter_node_template" {
  count = var.cluster_created && var.autoscaling_type == "karpenter" ? 1 : 0

  yaml_body = <<EOF
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: "karpenter"
spec:
  amiFamily: "AL2023"
  securityGroupSelectorTerms:
  - tags:
      Name: "${var.cluster_name}-node"
  subnetSelectorTerms:
  - tags:
      "${var.karpenter["karpenter_subnet_key"]}" : "${var.karpenter["karpenter_subnet_value"]}"
  instanceProfile: "${aws_iam_instance_profile.karpenter[0].name}"
  tags:
    ${jsonencode(var.tags)}
  blockDeviceMappings:
  - deviceName: "${var.karpenter["disk_device_name"]}"
    ebs:
      volumeSize: ${var.karpenter["disk_size"]}
      volumeType: "gp3"
      deleteOnTermination: true
EOF
}



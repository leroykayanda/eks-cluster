# ALB controller helm chart

resource "helm_release" "lb" {
  count      = var.cluster_created ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.3"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = var.lb_service_name
  }
}

# Create service account
resource "aws_iam_role" "lb_role" {
  count = var.cluster_created ? 1 : 0
  name  = "${var.cluster_name}-${var.lb_service_name}"
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

resource "aws_iam_policy" "lb" {
  count = var.cluster_created ? 1 : 0
  name  = "${var.cluster_name}-${var.lb_service_name}"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "iam:CreateServiceLinkedRole"
          Condition = {
            StringEquals = {
              "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
            }
          }
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetGroupAttributes",
            "elasticloadbalancing:DescribeTags",
            "elasticloadbalancing:DescribeSSLPolicies",
            "elasticloadbalancing:DescribeRules",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeListenerCertificates",
            "ec2:GetCoipPoolUsage",
            "ec2:DescribeVpcs",
            "ec2:DescribeVpcPeeringConnections",
            "ec2:DescribeTags",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeInstances",
            "ec2:DescribeCoipPools",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeAddresses",
            "ec2:DescribeAccountAttributes",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "wafv2:GetWebACLForResource",
            "wafv2:GetWebACL",
            "wafv2:DisassociateWebACL",
            "wafv2:AssociateWebACL",
            "waf-regional:GetWebACLForResource",
            "waf-regional:GetWebACL",
            "waf-regional:DisassociateWebACL",
            "waf-regional:AssociateWebACL",
            "shield:GetSubscriptionState",
            "shield:DescribeProtection",
            "shield:DeleteProtection",
            "shield:CreateProtection",
            "iam:ListServerCertificates",
            "iam:GetServerCertificate",
            "cognito-idp:DescribeUserPoolClient",
            "acm:ListCertificates",
            "acm:DescribeCertificate",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "ec2:RevokeSecurityGroupIngress",
            "ec2:AuthorizeSecurityGroupIngress",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = "ec2:CreateSecurityGroup"
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = "ec2:CreateTags"
          Condition = {
            Null = {
              "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
            }
            StringEquals = {
              "ec2:CreateAction" = "CreateSecurityGroup"
            }
          }
          Effect   = "Allow"
          Resource = "arn:aws:ec2:*:*:security-group/*"
        },
        {
          Action = [
            "ec2:DeleteTags",
            "ec2:CreateTags",
          ]
          Condition = {
            Null = {
              "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
              "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
            }
          }
          Effect   = "Allow"
          Resource = "arn:aws:ec2:*:*:security-group/*"
        },
        {
          Action = [
            "ec2:RevokeSecurityGroupIngress",
            "ec2:DeleteSecurityGroup",
            "ec2:AuthorizeSecurityGroupIngress",
          ]
          Condition = {
            Null = {
              "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
            }
          }
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "elasticloadbalancing:CreateTargetGroup",
            "elasticloadbalancing:CreateLoadBalancer",
          ]
          Condition = {
            Null = {
              "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
            }
          }
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "elasticloadbalancing:DeleteRule",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:CreateListener",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "elasticloadbalancing:RemoveTags",
            "elasticloadbalancing:AddTags",
          ]
          Condition = {
            Null = {
              "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
              "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
            }
          }
          Effect = "Allow"
          Resource = [
            "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
          ]
        },
        {
          Action = [
            "elasticloadbalancing:RemoveTags",
            "elasticloadbalancing:AddTags",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
          ]
        },
        {
          Action = [
            "elasticloadbalancing:SetSubnets",
            "elasticloadbalancing:SetSecurityGroups",
            "elasticloadbalancing:SetIpAddressType",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:DeleteTargetGroup",
            "elasticloadbalancing:DeleteLoadBalancer",
          ]
          Condition = {
            Null = {
              "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
            }
          }
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = "elasticloadbalancing:AddTags"
          Condition = {
            Null = {
              "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
            }
            StringEquals = {
              "elasticloadbalancing:CreateAction" = [
                "CreateTargetGroup",
                "CreateLoadBalancer",
              ]
            }
          }
          Effect = "Allow"
          Resource = [
            "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
          ]
        },
        {
          Action = [
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets",
          ]
          Effect   = "Allow"
          Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
          Action = [
            "elasticloadbalancing:SetWebAcl",
            "elasticloadbalancing:RemoveListenerCertificates",
            "elasticloadbalancing:ModifyRule",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:AddListenerCertificates",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "lb_attachment" {
  count      = var.cluster_created ? 1 : 0
  role       = aws_iam_role.lb_role[0].name
  policy_arn = aws_iam_policy.lb[0].arn
}

resource "kubernetes_service_account" "lb" {
  count = var.cluster_created ? 1 : 0
  metadata {
    name      = var.lb_service_name
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb_role[0].arn
    }
  }
  automount_service_account_token = true
}

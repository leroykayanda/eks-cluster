resource "kubernetes_namespace" "ns" {
  metadata {
    name = "${var.env}-${var.service}"
  }
}

#app DNS record

data "aws_lb" "ingress" {
  name = "${var.env}-eks-cluster"
}

resource "aws_route53_record" "alb" {
  zone_id = var.zone_id
  name    = var.dns_name[var.env]
  type    = "A"

  alias {
    name                   = data.aws_lb.ingress.dns_name
    zone_id                = data.aws_lb.ingress.zone_id
    evaluate_target_health = false
  }
}

#app permissions
resource "aws_iam_role" "role" {
  name = "${var.env}-${var.service}"
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
  name = "${var.env}-${var.service}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:DeleteObject",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "kubernetes_service_account" "this" {
  depends_on = [kubernetes_namespace.ns]

  metadata {
    name      = var.service
    namespace = "${var.env}-${var.service}"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.role.arn
    }
  }
  automount_service_account_token = true
}

#number of running pods in a service alarm
resource "aws_cloudwatch_metric_alarm" "service_number_of_running_pods" {
  alarm_name          = "${var.env}-${var.service}-No-Running-Pods"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "service_number_of_running_pods"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This alarm monitors for when there are no running pods in a service"
  alarm_actions       = [var.sns_topic[var.env]]
  ok_actions          = [var.sns_topic[var.env]]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    Service     = var.service
    Namespace   = "${var.env}-${var.service}"
    ClusterName = "${var.kubernetes_cluster_env[var.env]}-${var.kubernetes_cluster_name}"
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

#pod mem usage alarm
resource "aws_cloudwatch_metric_alarm" "pod_memory_utilization_over_pod_limit" {
  alarm_name          = "${var.env}-${var.service}-High-Memory-Usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "pod_memory_utilization_over_pod_limit"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors for high memory usage"
  alarm_actions       = [var.sns_topic[var.env]]
  ok_actions          = [var.sns_topic[var.env]]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    Service     = var.service
    Namespace   = "${var.env}-${var.service}"
    ClusterName = "${var.kubernetes_cluster_env[var.env]}-${var.kubernetes_cluster_name}"
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

#pod cpu usage alarm
resource "aws_cloudwatch_metric_alarm" "pod_cpu_utilization_over_pod_limit" {
  alarm_name          = "${var.env}-${var.service}-High-CPU-Usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "pod_cpu_utilization_over_pod_limit"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors for high cpu usage"
  alarm_actions       = [var.sns_topic[var.env]]
  ok_actions          = [var.sns_topic[var.env]]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    Service     = var.service
    Namespace   = "${var.env}-${var.service}"
    ClusterName = "${var.kubernetes_cluster_env[var.env]}-${var.kubernetes_cluster_name}"
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

#argocd app
resource "argocd_application" "app" {
  metadata {
    name        = "${var.env}-${var.service}"
    namespace   = "argocd"
    annotations = var.argo_annotations[var.env]
    labels = {
      service = var.service
      env     = var.env
    }
  }

  spec {
    source {
      repo_url        = var.argo_repo
      target_revision = var.argo_target_revision[var.env]
      path            = var.argo_path[var.env]
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "${var.env}-${var.service}"
    }
    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = false
      }
      sync_options = [
        "Validate=true",
        "CreateNamespace=false",
        "PrunePropagationPolicy=foreground"
      ]
    }

    ignore_difference {
      group         = "apps"
      kind          = "Deployment"
      json_pointers = ["/spec/replicas"]
    }
  }
}

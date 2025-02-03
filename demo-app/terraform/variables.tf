# General

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "service" {
  type        = string
  description = "The name of the product or service being built"
  default     = "demo-app"
}

variable "env" {
  type        = string
  description = "The environment i.e prod, dev etc"
}

variable "sns_topic" {
  type = map(string)
  default = {
    "staging" = "arn:aws:sns:eu-west-1:REDACTED:Tell-Developers"
    "prod"    = ""
  }
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "app_secrets" {
  default = {
    FOO = "BAR"
  }

  type = map(string)
}

variable "tags" {
  type = map(map(string))
  default = {
    "staging" = {
      Environment = "staging"
      Team        = "devops"
    }
  }
}

# R53 alias

variable "zone_id" {
  type        = string
  description = "Route53 zone to create app dns name in"
  default     = "Z02331641ZV9FCTVJLHSG"
}

variable "dns_name" {
  type        = map(string)
  description = "dns name of the app"
  default = {
    "staging" = "demo-app.demo.rentrahisi.co.ke"
    "prod"    = ""
  }
}

variable "metrics_type" {
  description = "cloudwatch or prometheus-grafana"
  default     = "prometheus-grafana"
}

# Kubernetes

variable "kubernetes_cluster_name" {
  type    = string
  default = "demo"
}

variable "kubernetes_cluster_env" {
  type = map(string)
  default = {
    "staging" = "staging"
  }
}

# Argocd

variable "argo_annotations" {
  type = map(map(string))
  default = {
    "staging" = {
      "notifications.argoproj.io/subscribe.on-health-degraded.slack" = "rentrahisi"
      "argocd-image-updater.argoproj.io/image-list"                  = "repo=521767246022.dkr.ecr.eu-west-1.amazonaws.com/staging-demo-app"
      "argocd-image-updater.argoproj.io/repo.update-strategy"        = "newest-build"
      "argocd-image-updater.argoproj.io/myimage.ignore-tags"         = "latest"
    },
    "prod" = {
    }
  }
}

variable "argocd" {
  type = any
  default = {
    "staging" = {
      repo_url        = "git@github.com:leroykayanda/eks-cluster.git"
      target_revision = "1.0.1"
      path            = "_helm-charts/app"
      server          = "staging-argocd.demo.rentrahisi.co.ke:443"
      value_files = [
        "../demo-app/base-values.yaml",
        "../demo-app/staging-values.yaml"
      ]
    }
  }
}

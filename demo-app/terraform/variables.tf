#general

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

variable "team" {
  type        = string
  description = "Used to tag resources"
  default     = "devops"
}

variable "sns_topic" {
  type = map(string)
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

#R53 alias
# variable "zone_id" {
#   type    = string
# }

# variable "dns_name" {
#   type = map(string)
# }

# variable "lb_dns_name" {
#   type = map(string)
# }

# variable "lb_zone_id" {
#   type = map(string)
# }

#k8s
variable "kubernetes_cluster_name" {
  type    = string
  default = "compute"
}

variable "kubernetes_cluster_env" {
  type = map(string)
  default = {
    "dev"   = "dev"
    "stage" = "dev"
    "sand"  = "dev"
    "prod"  = "prod"
  }
}

#argocd
# variable "argo_annotations" {
#   type = map(map(string))
#   default = {
#     "dev" = {
#       "notifications.argoproj.io/subscribe.on-health-degraded.slack" = "devops"
#       "argocd-image-updater.argoproj.io/image-list"                  = "repo=973967305414.dkr.ecr.eu-west-1.amazonaws.com/dev-references"
#       "argocd-image-updater.argoproj.io/repo.update-strategy"        = "latest"
#       "argocd-image-updater.argoproj.io/myimage.ignore-tags"         = "latest"
#     },
#     "prod" = {
#       "notifications.argoproj.io/subscribe.on-health-degraded.slack" = "devops"
#       "argocd-image-updater.argoproj.io/image-list"                  = "repo=973967305414.dkr.ecr.eu-west-1.amazonaws.com/prod-references"
#       "argocd-image-updater.argoproj.io/repo.update-strategy"        = "latest"
#       "argocd-image-updater.argoproj.io/myimage.ignore-tags"         = "latest"
#     }
#   }
# }

# variable "argo_repo" {
#   type    = string
#   default = "git@github.com:org/griot.git"
# }

# variable "argo_target_revision" {
#   type = map(string)
#   default = {
#     "dev"   = "dev"
#     "prod"  = "prod"
#   }
# }

# variable "argo_path" {
#   type = map(string)
#   default = {
#     "dev"   = "manifests/overlays/dev"
#     "prod"  = "manifests/overlays/prod"
#   }
# }

# variable "argo_server" {
#   type = map(string)
# }

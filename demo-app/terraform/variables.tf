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
variable "zone_id" {
  type    = string
  default = "Z10421303ISFAWMPOGQET"
}

variable "dns_name" {
  type = map(string)
  default = {
    "dev"  = "demo-app.rentrahisi.co.ke"
    "prod" = ""
  }
}

variable "lb_dns_name" {
  type = map(string)
  default = {
    "dev"  = "dev-eks-cluster-1403757379.eu-west-1.elb.amazonaws.com"
    "prod" = ""
  }
}

variable "lb_zone_id" {
  type = map(string)
  default = {
    "dev"  = "Z32O12XQLNTSW2"
    "prod" = ""
  }
}

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
variable "argo_annotations" {
  type = map(map(string))
  default = {
    "dev" = {
      "notifications.argoproj.io/subscribe.on-health-degraded.slack" = "rentrahisi"
      "argocd-image-updater.argoproj.io/image-list"                  = "repo=735265414519.dkr.ecr.eu-west-1.amazonaws.com/dev-demo-app"
      "argocd-image-updater.argoproj.io/repo.update-strategy"        = "latest"
      "argocd-image-updater.argoproj.io/myimage.ignore-tags"         = "latest"
    },
    "prod" = {
    }
  }
}

variable "argo_repo" {
  type    = string
  default = "git@github.com:leroykayanda/eks-cluster.git"
}

variable "argo_target_revision" {
  type = map(string)
  default = {
    "dev"  = "main"
    "prod" = ""
  }
}

variable "argo_path" {
  type = map(string)
  default = {
    "dev"  = "demo-app/manifests/overlays/dev"
    "prod" = "manifests/overlays/prod"
  }
}

variable "argo_server" {
  type = map(string)
  default = {
    "dev"  = "dev-argo.rentrahisi.co.ke:443"
    "prod" = ""
  }
}

#general

variable "region" {
  type    = string
  default = "eu-west-1"
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

variable "cluster_name" {
  type    = string
  default = "compute"
}

variable "sns_topic" {
  type = map(string)
}

#vpc
variable "vpc_id" {
  type = map(string)
}

variable "private_subnets" {
  type = map(list(string))
}

variable "public_subnets" {
  type = map(list(string))
  default = {
    "dev"  = [],
    "prod" = []
  }
}

#k8s
variable "cluster_created" {
  description = "create applications such as argocd only when the eks cluster has already been created"
  default     = true
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "nodegroup_properties" {
  type = any
  default = {
    "dev" = {
      "min_size"       = 1
      "max_size"       = 2
      "desired_size"   = 1
      "instance_types" = ["t3.small"]
      "capacity_type"  = "ON_DEMAND"
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 200
            delete_on_termination = true
          }
        }
      }
    }
    "prod" = {
    }
  }
}

variable "access_entries" {
  type        = map(any)
  default     = {}
  description = "Map of access entries for the EKS cluster"
}

variable "load_balancer_attributes" {
  type    = string
  default = "access_logs.s3.enabled=true,access_logs.s3.bucket=dev-eks-cluster-alb-access-logs,idle_timeout.timeout_seconds=900"
}

variable "target_group_attributes" {
  type    = string
  default = "deregistration_delay.timeout_seconds=5"
}

variable "tags" {
  type    = string
  default = "Environment=dev,Team=devops"
}

variable "company_name" {
  type        = string
  description = "To make ELB access log bucket name unique"
  default     = "rentrahisi"
}

#argoCD

variable "zone_id" {
  type    = string
  default = "Z0052717WJUA8A2U4AH1"
}

variable "argocd_image_updater_values" {
  type = map(list(string))
  default = {
    "dev" = [
      <<EOF
config:
  registries:
    - name: dev-references
      api_url: https://973967305414.dkr.ecr.eu-west-1.amazonaws.com
      prefix: 973967305414.dkr.ecr.eu-west-1.amazonaws.com
      ping: yes
      insecure: no
      credentials: ext:/scripts/ecr-login.sh
      credsexpire: 9h
authScripts:
  enabled: true
  scripts:
    ecr-login.sh: |
      #!/bin/sh
      aws ecr --region eu-west-1 get-authorization-token --output text --query 'authorizationData[].authorizationToken' | base64 -d
EOF
    ],
    "prod" = [
    ]
  }
}

variable "argo_subnets" {
  type = map(string)
  default = {
    "dev"  = "subnet-0a927928904638826 , subnet-0caebfd9ff05daff8"
    "prod" = ""
  }
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "argo_domain_name" {
  type = map(string)
  default = {
    "dev"  = ""
    "prod" = ""
  }
}

variable "argo_lb_dns_name" {
  type = map(string)
  default = {
    "dev"  = ""
    "prod" = ""
  }
}

variable "argo_lb_zone_id" {
  type = map(string)
  default = {
    "dev"  = ""
    "prod" = ""
  }
}

# variable "argo_ssh_private_key" {
#   description = "The SSH private key"
#   type        = string
# }

variable "argo_repo" {
  type    = string
  default = ""
}

# variable "argo_slack_token" {
#   type = string
# }

variable "argo_elb_timeout" {
  type    = number
  default = 900
}

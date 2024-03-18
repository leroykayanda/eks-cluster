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
  default = {
    "dev"  = "vpc-a55451c3"
    "prod" = ""
  }
}

variable "private_subnets" {
  type = map(list(string))
  default = {
    "dev"  = ["subnet-39eb5b63", "subnet-9781f6f1"],
    "prod" = []
  }
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

variable "argo_load_balancer_attributes" {
  type = map(string)
  default = {
    "dev"  = "access_logs.s3.enabled=true,access_logs.s3.bucket=dev-rentrahisi-eks-cluster-alb-access-logs,idle_timeout.timeout_seconds=300"
    "prod" = ""
  }
}

variable "argo_target_group_attributes" {
  type = map(string)
  default = {
    "dev"  = "deregistration_delay.timeout_seconds=5"
    "prod" = ""
  }
}

variable "argo_tags" {
  type = map(string)
  default = {
    "dev"  = "Environment=dev,Team=devops"
    "prod" = ""
  }
}

variable "company_name" {
  type        = string
  description = "To make ELB access log bucket name unique"
  default     = "rentrahisi"
}

#argoCD

variable "zone_id" {
  type    = string
  default = "Z10421303ISFAWMPOGQET"
}

variable "argo_subnets" {
  type = map(string)
  default = {
    "dev"  = "subnet-39eb5b63, subnet-9781f6f1"
    "prod" = ""
  }
}

variable "certificate_arn" {
  type    = string
  default = "arn:aws:acm:eu-west-1:735265414519:certificate/eab25873-8e9c-4895-bd1a-80a1eac6a09e"
}

variable "argo_domain_name" {
  type = map(string)
  default = {
    "dev"  = "dev-argo.rentrahisi.co.ke"
    "prod" = ""
  }
}

variable "argo_lb_dns_name" {
  type = map(string)
  default = {
    "dev"  = "dev-eks-cluster-1403757379.eu-west-1.elb.amazonaws.com"
    "prod" = ""
  }
}

variable "argo_lb_zone_id" {
  type = map(string)
  default = {
    "dev"  = "Z32O12XQLNTSW2"
    "prod" = ""
  }
}

variable "argo_ssh_private_key" {
  description = "The SSH private key"
  type        = string
}

variable "argo_repo" {
  type    = string
  default = "git@github.com:leroykayanda"
}

# variable "argo_slack_token" {
#   type = string
# }

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

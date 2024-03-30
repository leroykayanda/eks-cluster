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
  default = {
    "dev"  = "arn:aws:sns:eu-west-1:REDACTED:Tell-Developers"
    "prod" = ""
  }
}

#k8s
variable "cluster_created" {
  description = "create applications such as argocd only when the eks cluster has already been created"
  default = {
    "dev"  = false
    "prod" = false
  }
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
  type = map(any)
  default = {
    mike = {
      kubernetes_group = []
      principal_arn    = "arn:aws:iam::1234567:user/mike"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            namespaces = []
            type       = "cluster"
          }
        }
      }
    }
  }
  description = "Map of access entries for the EKS cluster. Used to authenticate users to the cluster"
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
  type        = string
  default     = "Z10421303ISFAWMPOGQET"
  description = "Route53 zone to create ArgoCD dns name in"
}

variable "certificate_arn" {
  type        = string
  default     = "arn:aws:acm:eu-west-1:735265414519:certificate/eab25873-8e9c-4895-bd1a-80a1eac6a09e"
  description = "ACM certificate to be used by ingress"
}

variable "argo_domain_name" {
  type        = map(string)
  description = "domain name for argocd ingress"
  default = {
    "dev"  = "dev-argo.rentrahisi.co.ke"
    "prod" = ""
  }
}

variable "argo_ssh_private_key" {
  description = "The SSH private key. ArgoCD uses this to authenticate to the repos in your github org"
  type        = string
}

variable "argo_repo" {
  type        = string
  description = "repo where manifest files needed by argocd are stored"
  default     = "git@github.com:leroykayanda"
}

variable "argo_slack_token" {
  type        = string
  default     = "xoxb-redacted"
  description = "Used by ArgoCD notifications to send alerts to Slack"
}

variable "argocd_image_updater_values" {
  type        = list(string)
  description = "specifies authentication details needed by argocd image updater"
  default = [
    <<EOF
config:
  registries:
    - name: ECR
      api_url: https://735265414519.dkr.ecr.eu-west-1.amazonaws.com
      prefix: 735265414519.dkr.ecr.eu-west-1.amazonaws.com
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
  ]
}

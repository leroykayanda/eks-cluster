# General

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "env" {
  type        = string
  description = "The environment i.e prod, dev etc"
}

variable "sns_topic" {
  type        = map(string)
  description = "For alarms"
  default = {
    "staging" = "arn:aws:sns:eu-west-1:735265414519:project-x-notifications"
  }
}

variable "vpc_id" {
  type        = map(string)
  description = "Name of the service"
  default = {
    "staging" = "vpc-01ffc244c8957b246"
  }
}

variable "vpc_cidr" {
  type        = map(string)
  description = "Name of the service"
  default = {
    "staging" = "10.2.0.0/16"
  }
}

variable "private_subnets" {
  type = map(list(string))
  default = {
    "staging" = ["subnet-0427cff875c517252", "subnet-039e8927cd8f1a352"]
  }
}

variable "public_subnets" {
  type = map(list(string))
  default = {
    "staging" = ["subnet-02c830b731654f848", "subnet-0533bd5827ce9806c"]
  }
}

variable "tags" {
  type = map(map(string))
  default = {
    "staging" = {
      Environment          = "staging"
      Team                 = "project-x"
      managed_by_terraform = "True"
    }
  }
}

variable "cluster_tags" {
  type = map(map(string))
  default = {
    "staging" = {
      Environment                               = "staging"
      Team                                      = "project-x"
      managed_by_terraform                      = "True"
      "kubernetes.io/cluster/staging-recon-eks" = "shared"
    }
  }
}

# Kubernetes

variable "cluster_created" {
  description = "create applications such as argocd only when the eks cluster has already been created"
  default = {
    "staging" = false
    "prod"    = false
  }
}

variable "cluster_not_terminated" {
  default = {
    "staging" = false
    "prod"    = false
  }
}

variable "cluster_name" {
  type    = string
  default = "recon-eks"
}

variable "cluster_version" {
  type    = string
  default = "1.30"
}

variable "initial_nodegroup" {
  type = any
  default = {
    "staging" = {
      "min_size"       = 1
      "max_size"       = 2
      "desired_size"   = 1
      "instance_types" = ["t3.medium"]
      "capacity_type"  = "ON_DEMAND"
      "iam_role_additional_policies" = {
        AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
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

variable "critical_nodegroup" {
  type = any
  default = {
    "staging" = {
      "min_size"       = 2
      "max_size"       = 2
      "desired_size"   = 2
      "instance_types" = ["t3.large"]
      "capacity_type"  = "ON_DEMAND"
      labels = {
        priority = "critical"
      }
      taints = [
        {
          key    = "priority"
          value  = "critical"
          effect = "NO_SCHEDULE"
        }
      ]
      "iam_role_additional_policies" = {
        AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
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

variable "certificate_arn" {
  type        = string
  default     = "arn:aws:acm:eu-west-1:735265414519:certificate/f8e0c747-52d8-48d1-8645-f42d976038df"
  description = "ACM certificate to be used by ingress"
}

variable "zone_id" {
  type        = string
  default     = "Z0052717WJUA8A2U4AH1"
  description = "Route53 zone to create DNS records in"
}

variable "company_name" {
  type        = string
  description = "To make ELB access log bucket name unique"
  default     = "rentrahisi"
}

variable "metrics_type" {
  description = "cloudwatch or prometheus-grafana"
  default     = "prometheus-grafana"
}

variable "logs_type" {
  description = "cloudwatch or elk"
  default     = "elk"
}

variable "autoscaling_type" {
  description = "cluster-autoscaler or karpenter"
  default     = "karpenter"
}

# ArgoCD

variable "argocd" {
  type = any
  default = {
    "staging" = {
      dns_name                 = "staging-argocd.rentrahisi.co.ke"
      repo                     = "git@github.com:leroykayanda"
      load_balancer_attributes = "access_logs.s3.enabled=true,access_logs.s3.bucket=staging-rentrahisi-eks-ingress-access-logs,idle_timeout.timeout_seconds=300"
      target_group_attributes  = "deregistration_delay.timeout_seconds=5"
      tags                     = "Environment=staging,Team=project-x"
    }
  }
}

variable "argocd_ssh_private_key" {
  description = "The SSH private key. ArgoCD uses this to authenticate to the repos in your github org. Generate a public/private key-pair. The private key is set here in terraform and the public key should be imported into github in Settings > SSH and GPG keys"
  type        = string
}

variable "argocd_slack_token" {
  type        = string
  default     = "xoxb-redacted"
  description = "Used by ArgoCD notifications to send alerts to Slack. The slack app should have chat:write permissions and should be installed in the channel it should post messages to"
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

# Karpenter

variable "karpenter" {
  type = any
  default = {
    "staging" = {
      replicas               = 2
      instance_types         = ["t3.medium", "t3.large", "t3.xlarge"]
      cpu_limit              = "4"
      memory_limit           = "8Gi"
      disruption_budget      = "50%"
      disk_size              = "100Gi"
      disk_device_name       = "/dev/xvda"
      karpenter_subnet_key   = "karpenter_can_use"
      karpenter_subnet_value = "true"
      expire_after           = "720h"
    }
  }
}

# ELK and Grafana

variable "elastic_password" {
  type = string
}

variable "elastic" {
  type = any
  default = {
    "staging" = {
      replicas           = 2
      minimumMasterNodes = 2
      pv_storage         = "5Gi"
      pv_access_mode     = "ReadWriteMany"
    }
  }
}

variable "kibana" {
  type = any
  default = {
    "staging" = {
      dns_name = "staging-kibana.rentrahisi.co.ke"
    }
  }
}

variable "prometheus" {
  type = any
  default = {
    "staging" = {
      dns_name       = "staging-prometheus.rentrahisi.co.ke"
      pv_storage     = "5Gi"
      retention      = "180d"
      pv_access_mode = "ReadWriteMany"
    }
  }
}

variable "grafana" {
  type = any
  default = {
    "staging" = {
      dns_name       = "staging-grafana.rentrahisi.co.ke"
      pv_storage     = "5Gi"
      pv_access_mode = "ReadWriteMany"
    }
  }
}

variable "slack_incoming_webhook_url" {
  type        = string
  description = "Used by Grafana for sending out alerts."
}

variable "grafana_user" {
  type = string
}

variable "grafana_password" {
  type = string
}

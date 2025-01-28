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
}

variable "vpc_id" {
  type        = map(string)
  description = "Name of the service"
  default = {
    "staging"    = "vpc-01ffc244c8957b246"
    "production" = ""
  }
}

variable "vpc_cidr" {
  type        = map(string)
  description = "Name of the service"
  default = {
    "staging"    = "10.0.0.0/16"
    "production" = ""
  }
}

variable "private_subnets" {
  type = map(list(string))
  default = {
    "staging"    = ["10.0.1.0/24", "10.0.2.0/24"]
    "production" = []
  }
}

variable "public_subnets" {
  type = map(list(string))
  default = {
    "staging"    = ["10.0.3.0/24", "10.0.4.0/24"]
    "production" = []
  }
}

variable "azs" {
  type    = list(string)
  default = ["eu-west-1a", "eu-west-1b"]
}

variable "tags" {
  type = map(map(string))
  default = {
    "staging" = {
      Environment          = "staging"
      Team                 = "devops"
      managed_by_terraform = "True"
    },
    "production" = {
      Environment          = "production"
      Team                 = "devops"
      managed_by_terraform = "True"
    }
  }
}

# Kubernetes

variable "cluster_created" {
  description = "create applications such as argocd only when the eks cluster has already been created"
  default = {
    "staging"    = false
    "production" = false
  }
}

variable "cluster_not_terminated" {
  default = {
    "staging"    = false
    "production" = false
  }
}

variable "cluster_name" {
  type    = string
  default = "demo"
}

variable "cluster_version" {
  type    = string
  default = "1.32"
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
    "production" = {
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
    "production" = {
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

variable "base_domain_name" {
  type    = string
  default = "demo.rentrahisi.co.ke"
}

# variable "certificate_arn" {
#   type        = string
#   default     = "arn:aws:acm:eu-west-1:521767246022:certificate/1f819e83-ff11-4f03-b87a-65a130fc6d86"
#   description = "ACM certificate to be used by ingress"
# }

# variable "zone_id" {
#   type        = string
#   default     = "Z02331641ZV9FCTVJLHSG"
#   description = "Route53 zone to create DNS records in"
# }

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
  type = map(map(string))
  default = {
    "staging" = {
      dns_name                 = "staging-argocd.demo.rentrahisi.co.ke"
      repo                     = "git@github.com:leroykayanda"
      load_balancer_attributes = "access_logs.s3.enabled=true,access_logs.s3.bucket=staging-rentrahisi-eks-ingress-access-logs,idle_timeout.timeout_seconds=300"
      target_group_attributes  = "deregistration_delay.timeout_seconds=5"
      tags                     = "Environment=staging,Team=devops"
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
      api_url: https://521767246022.dkr.ecr.eu-west-1.amazonaws.com
      prefix: 521767246022.dkr.ecr.eu-west-1.amazonaws.com
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
      cpu_limit              = "8"
      memory_limit           = "16Gi"
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
      dns_name = "staging-kibana.demo.rentrahisi.co.ke"
    }
  }
}

variable "prometheus" {
  type = any
  default = {
    "staging" = {
      dns_name       = "staging-prometheus.demo.rentrahisi.co.ke"
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
      dns_name       = "staging-grafana.demo.rentrahisi.co.ke"
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

# Keycloak

variable "keycloak" {
  type        = map(any)
  description = "Various keycloak settings"
  default = {
    "staging" = {
      dns_name   = "staging-keycloak.demo.rentrahisi.co.ke"
      url        = "https://staging-keycloak.demo.rentrahisi.co.ke"
      realm_name = "DEMO"
    }
  }
}

variable "keycloak_aurora_settings" {
  type = map(map(any))
  default = {
    "staging" = {
      "parameter_group_family"                 = "aurora-postgresql16"
      "engine"                                 = "aurora-postgresql",
      "engine_version"                         = "16.1",
      "engine_mode"                            = "provisioned",
      "serverless_cluster"                     = false
      "backup_retention_period"                = 35,
      "port"                                   = 5432,
      "instance_class"                         = "db.t4g.medium"
      "db_instance_count"                      = 1,
      "publicly_accessible"                    = false,
      "performance_insights_retention_period"  = 31
      "freeable_memory_alarm_threshold"        = 1000000000
      "disk_queue_depth_alarm_threshold"       = 200
      "buffer_cache_hit_ratio_alarm_threshold" = 80
      "dbload_alarm_threshold"                 = 1
    }
  }
}

variable "keycloak_credentials" {
  type        = map(string)
  description = "keycloak user and password"
  default = {
    user     = "value"
    password = "value"
  }
}

variable "keycloak_db_credentials" {
  type        = map(string)
  description = "keycloak DB credentials"
  default = {
    user     = "value"
    password = "value"
    db_name  = "value"
  }
}

# Miscellaneous

variable "placeholder_pods" {
  type        = map(number)
  description = "Number of placeholder pods to schedule. Will be evicted if we need to schedule higher priority pods"
  default = {
    staging = 0
  }
}

variable "istio" {
  type = map(map(string))
  default = {
    "staging" = {
      set_up_istio   = true
      kiali_dns_name = "staging-kiali.demo.rentrahisi.co.ke"
    }
  }
}



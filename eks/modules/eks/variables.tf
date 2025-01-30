variable "env" {
  type        = string
  description = "Deployment environment eg prod, dev"
}

variable "region" {
  type = string
}

variable "cluster_created" {
  type        = bool
  description = "create applications such as argocd only when the eks cluster has already been created"
  default     = false
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "access_entries" {
  type        = map(any)
  default     = {}
  description = "Map of access entries for the EKS cluster to control access on the cluster"
}

variable "public_ingress_subnets" {
  type        = string
  description = "Public subnets to be used by ingress"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate for use by ingress"
}

variable "zone_id" {
  type        = string
  description = "Route53 zone to create DNS names that point to ingress"
}

variable "keycloak" {
  type        = map(any)
  description = "Various keycloak settings"
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

variable "keycloak_db_hostname" {
  type        = string
  description = "DB hostname"
}

# Optional inputs. We have setup sensible defaults

variable "company_name" {
  type        = string
  description = "To make the ELB access log bucket name unique"
  default     = "contoso"
}

variable "sns_topic" {
  type        = string
  description = "SNS topic ARN for cloudwatch alarm notifications"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Used to tag resources"
  default     = {}
}

variable "metrics_type" {
  type        = string
  description = "cloudwatch or prometheus-grafana"
  default     = "prometheus-grafana"
}

variable "logs_type" {
  type        = string
  description = "cloudwatch or elk"
  default     = "elk"
}

variable "autoscaling_type" {
  type        = string
  description = "cluster-autoscaler or karpenter"
  default     = "karpenter"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Should the API server be in a public subnet?"
  default     = true
}

variable "initial_nodegroup" {
  type        = any
  description = "Initial nodegroup settings"
  default = {
    "min_size"       = 1
    "max_size"       = 2
    "desired_size"   = 1
    "instance_types" = ["t4g.2xlarge"]
    "capacity_type"  = "ON_DEMAND"
  }
}

variable "critical_nodegroup" {
  type        = any
  description = "Critical nodegroup settings"
  default = {
    "min_size"       = 2
    "max_size"       = 2
    "desired_size"   = 1
    "instance_types" = ["t4g.2xlarge"]
    "capacity_type"  = "ON_DEMAND"
  }
}

variable "autoscaler_service_name" {
  type        = string
  description = "value"
  default     = "cluster-autoscaler-sa"
}

variable "container_insights_service_name" {
  type        = string
  description = "Service account used by container insights helm chart"
  default     = "container-insights"
}

variable "lb_service_name" {
  type        = string
  description = "Service account used by the AWS load balancer controller helm chart"
  default     = "lb-controller"
}

variable "create_access_logs_bucket" {
  type        = bool
  default     = true
  description = "Whether to create ELB access logs bucket or not"
}

variable "create_pv_full_alert" {
  type        = bool
  description = "Create an alarm to alert when a Persistent Volume is full. Not needed when using EFS which has a very high storage limit."
  default     = false
}

variable "elb_security_policy" {
  type        = string
  description = "For TLS certificate"
  default     = "ELBSecurityPolicy-TLS13-1-2-Ext2-2021-06"
}

variable "elb_access_log_expiration" {
  type        = number
  description = "Days after which to delete ELB access logs"
  default     = 180
}

variable "argocd_ssh_private_key" {
  type        = string
  description = "The SSH private key used by ArgoCD to authenticate to Github"
  default     = null
}

variable "argocd_slack_token" {
  type        = string
  description = "Used to send ArgoCD notifications to Slack"
  default     = null
}

variable "argocd" {
  type        = map(string)
  description = "Various ArgoCD settings"
  default     = null
}

variable "karpenter" {
  type        = any
  description = "Various karpenter settings"
  default     = null
}

variable "argocd_image_updater_values" {
  type        = any
  description = "Various ArgoCD image updater settings"
  default     = null
}

variable "elastic" {
  type        = any
  description = "Various ELK settings"
  default     = null
}

variable "elastic_password" {
  type        = string
  description = "Elasticache password"
  default     = null
}

variable "kibana" {
  type        = any
  description = "Various Kibana settings"
  default     = null
}

variable "prometheus" {
  type        = any
  description = "Various prometheus settings"
  default     = null
}

variable "grafana" {
  type        = any
  description = "Various grafana settings"
  default     = null
}

variable "slack_incoming_webhook_url" {
  type        = string
  description = "Used by Grafana for sending out alerts."
  default     = null
}

variable "grafana_password" {
  type        = string
  description = "Grafana admin password"
  default     = null
}

variable "placeholder_pods" {
  type        = number
  description = "Number of placeholder pods to schedule. Will be evicted if we need to schedule higher priority pods"
  default     = 0
}

variable "istio" {
  type = map(string)
  default = {
    set_up_istio   = false
    kiali_dns_name = null
  }
}

variable "cluster_upgrade_policy" {
  type        = string
  description = "Configuration block for the cluster upgrade policy. Can be STANDARD or EXTENDED"
  default     = "STANDARD"
}

variable "cluster_enabled_log_types" {
  type        = list(string)
  description = "A list of the desired control plane logs to enable."
  default     = []
}

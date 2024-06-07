module "eks" {
  source                      = "app.terraform.io/RentRahisi/modules/cloud//aws/eks"
  version                     = "1.2.7"
  env                         = var.env
  team                        = var.team
  cluster_name                = "${var.env}-${var.cluster_name}"
  sns_topic                   = var.sns_topic[var.env]
  region                      = var.region
  vpc_id                      = module.vpc.vpc_id
  vpc_cidr                    = module.vpc.vpc_cidr_block
  private_subnets             = module.vpc.private_subnets
  public_ingress_subnets      = join(", ", module.vpc.public_subnets)
  initial_nodegroup           = var.initial_nodegroup[var.env]
  critical_nodegroup          = var.critical_nodegroup[var.env]
  access_entries              = var.access_entries
  cluster_version             = var.cluster_version
  cluster_created             = var.cluster_created[var.env]
  company_name                = var.company_name
  certificate_arn             = var.certificate_arn
  argocd                      = var.argocd[var.env]
  argo_ssh_private_key        = var.argo_ssh_private_key
  argo_slack_token            = var.argo_slack_token
  argocd_image_updater_values = var.argocd_image_updater_values
  metrics_type                = var.metrics_type
  logs_type                   = var.logs_type
  autoscaling_type            = var.autoscaling_type
  zone_id                     = var.zone_id
  karpenter                   = var.karpenter[var.env]
  elastic_password            = var.elastic_password
  elastic                     = var.elastic[var.env]
  kibana                      = var.kibana[var.env]
  prometheus                  = var.prometheus[var.env]
  grafana                     = var.grafana[var.env]
  slack_incoming_webhook_url  = var.slack_incoming_webhook_url
  grafana_password            = var.grafana_password

  providers = {
    kubernetes = kubernetes
    kubectl    = kubectl
    helm       = helm
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.env}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  private_subnet_tags = {
    type = "private-subnet"
  }

  tags = {
    Team        = var.team
    Environment = var.env
  }
}

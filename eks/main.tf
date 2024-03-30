module "eks" {
  source                        = "app.terraform.io/RentRahisi/modules/cloud//aws/eks"
  version                       = "1.0.25"
  env                           = var.env
  team                          = var.team
  cluster_name                  = "${var.env}-${var.cluster_name}"
  sns_topic                     = var.sns_topic[var.env]
  region                        = var.region
  vpc_id                        = module.vpc.vpc_id
  subnet_ids                    = module.vpc.private_subnets
  nodegroup_properties          = var.nodegroup_properties[var.env]
  access_entries                = var.access_entries
  cluster_version               = var.cluster_version
  cluster_created               = var.cluster_created[var.env]
  company_name                  = var.company_name
  argo_subnets                  = join(", ", module.vpc.public_subnets)
  certificate_arn               = var.certificate_arn
  argo_load_balancer_attributes = var.argo_load_balancer_attributes[var.env]
  argo_target_group_attributes  = var.argo_target_group_attributes[var.env]
  argo_tags                     = var.argo_tags[var.env]
  argo_domain_name              = var.argo_domain_name[var.env]
  argo_zone_id                  = var.zone_id
  argo_repo                     = var.argo_repo
  argo_ssh_private_key          = var.argo_ssh_private_key
  argo_slack_token              = var.argo_slack_token
  argocd_image_updater_values   = var.argocd_image_updater_values

  providers = {
    kubernetes = kubernetes
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

  tags = {
    Team        = var.team
    Environment = var.env
  }
}

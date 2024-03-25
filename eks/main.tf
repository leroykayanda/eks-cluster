module "eks" {
  source                        = "app.terraform.io/RentRahisi/modules/cloud//aws/eks"
  version                       = "1.0.14"
  env                           = var.env
  team                          = var.team
  cluster_name                  = "${var.env}-${var.cluster_name}"
  sns_topic                     = var.sns_topic[var.env]
  region                        = var.region
  vpc_id                        = var.vpc_id[var.env]
  subnet_ids                    = var.private_subnets[var.env]
  nodegroup_properties          = var.nodegroup_properties[var.env]
  access_entries                = var.access_entries
  cluster_version               = var.cluster_version
  cluster_created               = var.cluster_created
  company_name                  = var.company_name
  argo_subnets                  = var.argo_subnets[var.env]
  certificate_arn               = var.certificate_arn
  argo_load_balancer_attributes = var.argo_load_balancer_attributes[var.env]
  argo_target_group_attributes  = var.argo_target_group_attributes[var.env]
  argo_tags                     = var.argo_tags[var.env]
  argo_domain_name              = var.argo_domain_name[var.env]
  argo_zone_id                  = var.zone_id
  argo_lb_dns_name              = var.argo_lb_dns_name[var.env]
  argo_lb_zone_id               = var.argo_lb_zone_id[var.env]
  argo_repo                     = var.argo_repo
  argo_ssh_private_key          = var.argo_ssh_private_key
  argo_slack_token              = var.argo_slack_token
  argocd_image_updater_values   = var.argocd_image_updater_values

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}


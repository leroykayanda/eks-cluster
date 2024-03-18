module "eks" {
  source               = "app.terraform.io/RentRahisi/modules/cloud//aws/eks"
  version              = "1.0.7"
  env                  = var.env
  team                 = var.team
  cluster_name         = "${var.env}-${var.cluster_name}"
  sns_topic            = var.sns_topic[var.env]
  region               = var.region
  vpc_id               = var.vpc_id[var.env]
  subnet_ids           = var.private_subnets[var.env]
  nodegroup_properties = var.nodegroup_properties[var.env]
  access_entries       = var.access_entries
  cluster_version      = var.cluster_version
  cluster_created      = var.cluster_created
  company_name         = var.company_name

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}


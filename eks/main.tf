# module "eks" {
#   source                      = "./modules/eks"
#   env                         = var.env
#   cluster_name                = "${var.env}-${var.cluster_name}"
#   sns_topic                   = var.sns_topic[var.env]
#   region                      = var.region
#   vpc_id                      = var.vpc_id[var.env]
#   vpc_cidr                    = var.vpc_cidr[var.env]
#   private_subnets             = var.private_subnets[var.env]
#   public_ingress_subnets      = join(", ", var.public_subnets[var.env])
#   initial_nodegroup           = var.initial_nodegroup[var.env]
#   critical_nodegroup          = var.critical_nodegroup[var.env]
#   access_entries              = var.access_entries
#   cluster_version             = var.cluster_version
#   cluster_created             = var.cluster_created[var.env]
#   company_name                = var.company_name
#   certificate_arn             = var.certificate_arn
#   argocd                      = var.argocd[var.env]
#   argocd_ssh_private_key      = var.argocd_ssh_private_key
#   argocd_slack_token          = var.argocd_slack_token
#   argocd_image_updater_values = var.argocd_image_updater_values
#   metrics_type                = var.metrics_type
#   logs_type                   = var.logs_type
#   autoscaling_type            = var.autoscaling_type
#   zone_id                     = var.zone_id
#   karpenter                   = var.karpenter[var.env]
#   elastic_password            = var.elastic_password
#   elastic                     = var.elastic[var.env]
#   kibana                      = var.kibana[var.env]
#   prometheus                  = var.prometheus[var.env]
#   grafana                     = var.grafana[var.env]
#   slack_incoming_webhook_url  = var.slack_incoming_webhook_url
#   grafana_password            = var.grafana_password
#   placeholder_pods            = var.placeholder_pods[var.env]
#   istio                       = var.istio[var.env]
#   keycloak                    = var.keycloak[var.env]
#   keycloak_credentials        = var.keycloak_credentials
#   keycloak_db_hostname        = module.keycloak_aurora_db.aurora_writer_endpoint
#   tags                        = var.tags[var.env]

#   providers = {
#     kubernetes = kubernetes
#     kubectl    = kubectl
#     helm       = helm
#   }
# }

module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  name                   = "${var.env}-vpc"
  cidr                   = var.vpc_cidr[var.env]
  azs                    = var.azs
  private_subnets        = var.private_subnets[var.env]
  public_subnets         = var.public_subnets[var.env]
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  tags                   = var.tags[var.env]
}

module "keycloak_aurora_db" {
  source             = "./modules/aurora"
  service            = "keycloak"
  tags               = var.tags[var.env]
  env                = var.env
  db_subnets         = module.vpc.private_subnets
  aurora_settings    = var.keycloak_aurora_settings[var.env]
  db_credentials     = var.keycloak_db_credentials
  availability_zones = var.azs
  security_group_id  = aws_security_group.keycloak_db_sg.id
  region             = var.region
  sns_topic          = var.sns_topic[var.env]
}

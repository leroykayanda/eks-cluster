provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = var.cluster_created[var.env] || var.cluster_not_terminated[var.env] ? data.aws_eks_cluster.cluster[0].endpoint : ""
  cluster_ca_certificate = var.cluster_created[var.env] || var.cluster_not_terminated[var.env] ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : ""
  token                  = var.cluster_created[var.env] || var.cluster_not_terminated[var.env] ? data.aws_eks_cluster_auth.auth[0].token : ""
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_created[var.env] || var.cluster_not_terminated[var.env] ? data.aws_eks_cluster.cluster[0].endpoint : ""
    cluster_ca_certificate = var.cluster_created[var.env] || var.cluster_not_terminated[var.env] ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : ""
    token                  = var.cluster_created[var.env] || var.cluster_not_terminated[var.env] ? data.aws_eks_cluster_auth.auth[0].token : ""
  }
}

provider "kubectl" {
  host                   = var.cluster_created[var.env] || var.cluster_not_terminated[var.env] ? data.aws_eks_cluster.cluster[0].endpoint : ""
  cluster_ca_certificate = var.cluster_created[var.env] || var.cluster_not_terminated[var.env] ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : ""
  token                  = var.cluster_created[var.env] || var.cluster_not_terminated[var.env] ? data.aws_eks_cluster_auth.auth[0].token : ""
  load_config_file       = false
}

provider "grafana" {
  url  = "https://${var.grafana[var.env]["dns_name"]}"
  auth = "${var.grafana_user}:${var.grafana_password}"
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = var.keycloak_credentials["user"]
  password  = var.keycloak_credentials["password"]
  url       = var.keycloak[var.env]["url"]
}

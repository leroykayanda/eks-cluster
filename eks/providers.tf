provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = var.cluster_created[var.env] ? data.aws_eks_cluster.cluster[0].endpoint : ""
  cluster_ca_certificate = var.cluster_created[var.env] ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : ""
  token                  = var.cluster_created[var.env] ? data.aws_eks_cluster_auth.auth[0].token : ""
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_created[var.env] ? data.aws_eks_cluster.cluster[0].endpoint : ""
    cluster_ca_certificate = var.cluster_created[var.env] ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : ""
    token                  = var.cluster_created[var.env] ? data.aws_eks_cluster_auth.auth[0].token : ""
  }
}

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.auth.token
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.auth.token
#   }
# }


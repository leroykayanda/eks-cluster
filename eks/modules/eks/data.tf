data "aws_eks_cluster" "cluster" {
  count = var.cluster_created ? 1 : 0
  name  = var.cluster_name

  depends_on = [
    module.eks.eks_managed_node_groups,
  ]
}

data "aws_caller_identity" "current" {}

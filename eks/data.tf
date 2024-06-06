data "aws_eks_cluster" "cluster" {
  name  = "${var.env}-${var.cluster_name}"
  count = var.cluster_created[var.env] || var.cluster_not_terminated[var.env] ? 1 : 0
}

data "aws_eks_cluster_auth" "auth" {
  name  = "${var.env}-${var.cluster_name}"
  count = var.cluster_created[var.env] || var.cluster_not_terminated[var.env] ? 1 : 0
}

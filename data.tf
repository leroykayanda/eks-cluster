data "aws_eks_cluster" "cluster" {
  name = "${var.env}-${var.cluster_name}"
}

data "aws_eks_cluster_auth" "auth" {
  name = "${var.env}-${var.cluster_name}"
}

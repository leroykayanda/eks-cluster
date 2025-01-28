locals {
  eks_oidc_issuer = var.cluster_created ? trimprefix(data.aws_eks_cluster.cluster[0].identity[0].oidc[0].issuer, "https://") : ""
  karpenter_sa    = "karpenter-sa"

  ingress_annotations = {
    "alb.ingress.kubernetes.io/backend-protocol"         = "HTTP"
    "alb.ingress.kubernetes.io/listen-ports"             = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
    "alb.ingress.kubernetes.io/ssl-redirect"             = "443"
    "alb.ingress.kubernetes.io/scheme"                   = "internet-facing"
    "alb.ingress.kubernetes.io/load-balancer-name"       = "${var.env}-eks-cluster"
    "alb.ingress.kubernetes.io/subnets"                  = "${var.public_ingress_subnets}"
    "alb.ingress.kubernetes.io/certificate-arn"          = "${var.certificate_arn}"
    "alb.ingress.kubernetes.io/load-balancer-attributes" = var.argocd["load_balancer_attributes"]
    "alb.ingress.kubernetes.io/target-group-attributes"  = var.argocd["target_group_attributes"]
    "alb.ingress.kubernetes.io/ssl-policy"               = var.elb_security_policy
    "alb.ingress.kubernetes.io/success-codes"            = "200-499"
    "alb.ingress.kubernetes.io/tags"                     = var.argocd["tags"]
    "alb.ingress.kubernetes.io/group.name"               = var.env
  }
}

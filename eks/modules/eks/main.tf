module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "20.33.0"
  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_public_access           = var.cluster_endpoint_public_access
  vpc_id                                   = var.vpc_id
  subnet_ids                               = var.private_subnets
  authentication_mode                      = "API"
  cloudwatch_log_group_retention_in_days   = 30
  enable_cluster_creator_admin_permissions = true
  access_entries                           = var.access_entries
  cluster_enabled_log_types                = var.cluster_enabled_log_types

  cluster_addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent = true
    }

    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  eks_managed_node_groups = {
    initial-nodegroup  = var.initial_nodegroup
    critical-nodegroup = var.critical_nodegroup
  }

  cluster_upgrade_policy = {
    support_type = var.cluster_upgrade_policy
  }

  tags = merge(
    var.tags,
    { "kubernetes.io/cluster/${var.cluster_name}" = "shared" }
  )
}

module "access_logs_bucket" {
  count                          = var.create_access_logs_bucket ? 1 : 0
  source                         = "terraform-aws-modules/s3-bucket/aws"
  bucket                         = "${var.env}-${var.company_name}-eks-ingress-access-logs"
  acl                            = "log-delivery-write"
  force_destroy                  = true
  control_object_ownership       = true
  object_ownership               = "ObjectWriter"
  attach_elb_log_delivery_policy = true
  attach_lb_log_delivery_policy  = true
  tags                           = var.tags
  lifecycle_rule = [
    {
      id      = "expire_old_logs"
      enabled = true

      expiration = {
        days = var.elb_access_log_expiration
      }
    }
  ]
}


# EBS

resource "kubernetes_storage_class" "sc" {
  count = var.cluster_created ? 1 : 0
  metadata {
    name = "ebs"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true

  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }
}

# EFS

# EFS CSI driver helm chart

resource "helm_release" "aws_efs_csi_driver" {
  count      = var.cluster_created ? 1 : 0
  chart      = "aws-efs-csi-driver"
  name       = "aws-efs-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  version    = "3.0.4"

  set {
    name  = "controller.serviceAccount.create"
    value = false
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }
}

# Create service account

resource "aws_iam_role" "efs" {
  name = "${var.cluster_name}-efs-sa-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer}"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs" {
  role       = aws_iam_role.efs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

resource "kubernetes_service_account" "efs" {
  count = var.cluster_created ? 1 : 0
  metadata {
    name      = "efs-csi-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.efs.arn
    }
  }
  automount_service_account_token = true
}

# EFS file system

resource "aws_efs_file_system" "efs" {
  creation_token   = "${var.cluster_name}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
  encrypted        = true

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-efs"
    }
  )
}

# EFS security group

resource "aws_security_group" "efs" {
  name        = "${var.cluster_name}-efs-sg"
  description = "Allow inbound efs traffic from VPC CIDR"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks = [var.vpc_cidr]
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
  }

  tags = {
    Name = "${var.cluster_name}-efs-sg"
  }
}

# Mount target

resource "aws_efs_mount_target" "efs_mount_target" {
  count           = length(var.private_subnets)
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

# EFS storage class

resource "kubectl_manifest" "efs" {
  count = var.cluster_created ? 1 : 0

  yaml_body = <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: efs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer 
reclaimPolicy: Delete
allowVolumeExpansion: true
parameters:
  fileSystemId: "${aws_efs_file_system.efs.id}"
  provisioningMode: efs-ap
  directoryPerms: "777"
EOF
}


## Tearing down the infrastructure
- Delete all images from ECR
- Delete the test secret in secrets manager.
- Queue a destroy plan for the terraform workspace demo-app-aws-dev
- set the variable cluster_created to false in eks/variables.tf. 
- Run terraform apply. This will delete terraform applications such as argocd

set the value of eks/data.tf to be as below


    data "aws_eks_cluster" "cluster" {
      name = "${var.env}-${var.cluster_name}"
    }
    
    data "aws_eks_cluster_auth" "auth" {
      name = "${var.env}-${var.cluster_name}"
    }


and set the providers as below

     provider "kubernetes" {
         host                   = data.aws_eks_cluster.cluster.endpoint
         cluster_ca_certificate =      base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
         token                  = data.aws_eks_cluster_auth.auth.token
     }


    provider "helm" {
      kubernetes {
        host                   = data.aws_eks_cluster.cluster.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
        token                  = data.aws_eks_cluster_auth.auth.token
      }
    }

Queue a destroy plan for the eks-dev workspace.
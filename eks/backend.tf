terraform {
  backend "remote" {
    organization = "RentRahisi"

    workspaces {
      prefix = "recon-eks-"
    }
  }

  required_providers {

    aws = {
      version = "~> 5.67.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }

    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0.0"
    }

  }
}

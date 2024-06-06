terraform {
  backend "remote" {
    organization = "RentRahisi"

    workspaces {
      prefix = "aws-demo-app-"
    }
  }

  required_providers {

    aws = {
      version = "~> 5.52.0"
    }

    argocd = {
      source  = "oboukili/argocd"
      version = "~> 6.1.1"
    }

  }
}

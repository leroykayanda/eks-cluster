terraform {
  backend "remote" {
    organization = "RentRahisi"

    workspaces {
      prefix = "eks-"
    }
  }

  required_version = ">= 1.0.0"

  required_providers {

    aws = {
      version = ">= 5.41.0"
    }

  }
}

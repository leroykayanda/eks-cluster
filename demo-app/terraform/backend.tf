terraform {
  backend "remote" {
    organization = "RentRahisi"

    workspaces {
      prefix = "demo-app-"
    }
  }

  required_version = ">= 1.0.0"

  required_providers {

    aws = {
      version = ">= 5.41.0"
    }

  }
}

terraform {
  backend "remote" {
    organization = "RentRahisi"

    workspaces {
      prefix = "eks-"
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

    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.4.0"
    }

  }
}

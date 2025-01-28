terraform {

  required_providers {

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

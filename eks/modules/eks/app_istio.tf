# Istio namespace

resource "kubernetes_namespace" "istio" {
  count = var.cluster_created && var.istio["set_up_istio"] ? 1 : 0
  metadata {
    name = "istio-system"
  }
}

# Istio base chart (contains CRDs)

resource "helm_release" "istio_base" {
  count      = var.cluster_created && var.istio["set_up_istio"] ? 1 : 0
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = "istio-system"
  version    = "1.23.1"
}

# Istio control plane

resource "helm_release" "istio" {
  count      = var.cluster_created && var.istio["set_up_istio"] ? 1 : 0
  name       = "istio"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  version    = "1.23.1"

  values = [
    <<EOF
    defaults:
      pilot:
        resources: 
            requests:
              cpu: "500m"
              memory: "500Mi"
            limits:
              cpu: "1024m"
              memory: "1000Mi"
    EOF
  ]
}

# Allow API server access to istio service in worker nodes

resource "aws_vpc_security_group_ingress_rule" "istio" {
  count                        = var.istio["set_up_istio"] ? 1 : 0
  security_group_id            = module.eks.node_security_group_id
  description                  = "Cluster API to node 15017/tcp webhook"
  referenced_security_group_id = module.eks.cluster_security_group_id
  from_port                    = 15017
  ip_protocol                  = "tcp"
  to_port                      = 15017
}

# OIDC secret

resource "kubectl_manifest" "kiali_oidc_secret" {
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: istio-system
  labels:
    app: kiali
type: Opaque
data:
  oidc-secret: "${base64encode(keycloak_openid_client.openid_client_kiali[0].client_secret)}"
YAML
}


# Kiali helm chart

resource "helm_release" "kiali" {
  count      = var.cluster_created && var.istio["set_up_istio"] ? 1 : 0
  name       = "kiali"
  repository = "https://kiali.org/helm-charts"
  chart      = "kiali-operator"
  namespace  = "istio-system"
  version    = "2.4.0"

  set {
    name  = "cr.create"
    value = true
  }

  set {
    name  = "cr.namespace"
    value = "istio-system"
  }

  set {
    name  = "cr.spec.auth.strategy"
    value = "openid"
  }

  set {
    name  = "cr.spec.external_services.prometheus.url"
    value = "http://prometheus-server.grafana/"
  }

  set {
    name  = "cr.spec.deployment.service_type"
    value = "NodePort"
  }

  set {
    name  = "cr.spec.deployment.ingress.enabled"
    value = true
  }

  values = [
    <<EOF
    resources:
      requests:
          cpu: "250m"
          memory: "250Mi"
      limits:
          cpu: "500m"
          memory: "500Mi"
    cr:
      spec:
        auth:
          strategy: openid
          openid:
            client_id: "${keycloak_openid_client.openid_client_kiali[0].client_id}"              
            issuer_uri: "https://${var.keycloak["dns_name"]}/realms/${var.keycloak["realm_name"]}" 
            scopes: ["openid","${keycloak_openid_client_scope.kiali_client_scope[0].name}","email","profile"]
            username_claim: "email"
            authorization_endpoint: "https://${var.keycloak["dns_name"]}/realms/${var.keycloak["realm_name"]}/protocol/openid-connect/auth"
            disable_rbac: true
    EOF
  ]
}

# Kiali dns name

resource "aws_route53_record" "kiali" {
  count   = var.cluster_created && var.istio["set_up_istio"] ? 1 : 0
  zone_id = var.zone_id
  name    = var.istio["kiali_dns_name"]
  type    = "A"

  alias {
    name                   = data.aws_lb.ingress[0].dns_name
    zone_id                = data.aws_lb.ingress[0].zone_id
    evaluate_target_health = false
  }
}

# Kiali ingress

resource "kubernetes_ingress_v1" "kiali" {
  count = var.cluster_created && var.istio["set_up_istio"] ? 1 : 0
  metadata {
    name        = "kiali"
    namespace   = "istio-system"
    annotations = local.ingress_annotations
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.istio["kiali_dns_name"]

      http {
        path {
          path = "/*"

          backend {
            service {
              name = "kiali"
              port {
                number = 20001
              }
            }
          }

        }
      }
    }

    tls {
      hosts = [var.istio["kiali_dns_name"]]
    }
  }
}

# Kiali Keycloak

resource "keycloak_openid_client" "openid_client_kiali" {
  count                           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id                        = keycloak_realm.realm[0].id
  client_id                       = "kiali"
  name                            = "kiali"
  enabled                         = true
  access_type                     = "CONFIDENTIAL"
  standard_flow_enabled           = true
  valid_redirect_uris             = ["https://${var.istio["kiali_dns_name"]}/kiali/*"]
  root_url                        = "https://${var.istio["kiali_dns_name"]}"
  web_origins                     = ["https://${var.istio["kiali_dns_name"]}"]
  admin_url                       = "https://${var.istio["kiali_dns_name"]}"
  base_url                        = "https://${var.istio["kiali_dns_name"]}"
  valid_post_logout_redirect_uris = ["+"]
  direct_access_grants_enabled    = true
}

resource "keycloak_openid_client_scope" "kiali_client_scope" {
  count                  = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id               = keycloak_realm.realm[0].id
  name                   = "kiali_client_scope"
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "kiali_groups" {
  count           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id        = keycloak_realm.realm[0].id
  client_scope_id = keycloak_openid_client_scope.kiali_client_scope[0].id
  name            = "groups"
  claim_name      = "groups"
  full_path       = false
}

resource "keycloak_generic_protocol_mapper" "email_kiali" {
  count           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id        = keycloak_realm.realm[0].id
  client_scope_id = keycloak_openid_client_scope.kiali_client_scope[0].id
  name            = "email"
  protocol        = "openid-connect"
  protocol_mapper = "oidc-usermodel-attribute-mapper"
  config = {
    "access.token.claim"        = "true"
    "id.token.claim"            = "true"
    "userinfo.token.claim"      = "true"
    "full.path"                 = "false"
    "claim.name"                = "email"
    "jsonType.label"            = "String"
    "introspection.token.claim" = "false"
    "lightweight.claim"         = "false"
    "multivalued"               = "false"
    "user.attribute"            = "email"
    "aggregate.attrs"           = "false"
  }
}

resource "keycloak_openid_client_default_scopes" "client_default_scopes_kiali" {
  count          = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id       = keycloak_realm.realm[0].id
  client_id      = keycloak_openid_client.openid_client_kiali[0].id
  default_scopes = ["profile", "email", keycloak_openid_client_scope.kiali_client_scope[0].name]
}

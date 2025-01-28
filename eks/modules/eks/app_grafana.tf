# Grafana namespace

resource "kubernetes_namespace" "grafana" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  metadata {
    name = "grafana"
  }
}

# Prometheus helm chart

resource "helm_release" "prometheus" {
  count      = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  name       = "prometheus"
  chart      = "prometheus"
  version    = "25.21.0"
  repository = "https://prometheus-community.github.io/helm-charts"
  namespace  = "grafana"

  set {
    name  = "server.persistentVolume.size"
    value = var.prometheus["pv_storage"]
  }

  set {
    name  = "server.retention"
    value = var.prometheus["retention"]
  }

  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  values = [
    <<EOF
    server:
      tolerations:
      - key: "priority"
        operator: "Equal"
        value: "critical"
        effect: "NoSchedule"
      nodeSelector:
        priority: "critical"
      persistentVolume:
        accessModes: ["${var.prometheus["pv_access_mode"]}"]
      service:
        additionalPorts:
          - name: oauth2-proxy
            port: 4180
            targetPort: 4180
      sidecarContainers:
        oauth-proxy:
          image: quay.io/oauth2-proxy/oauth2-proxy:v7.1.2
          args:
            - --upstream=http://127.0.0.1:9090
            - --http-address=0.0.0.0:4180
            - --provider=oidc
            - --client-id=${keycloak_openid_client.openid_client_prometheus[0].client_id}
            - --client-secret=${keycloak_openid_client.openid_client_prometheus[0].client_secret}
            - --redirect-url=https://${var.prometheus["dns_name"]}/oauth2/callback
            - --oidc-issuer-url=https://${var.keycloak["dns_name"]}/realms/${var.keycloak["realm_name"]}
            - --scope=openid ${keycloak_openid_client_scope.prometheus_client_scope[0].name}
            - --cookie-secure=true
            - --cookie-secret=lZn0QCSAHMiSM9DTPkTQZhBTETPiQgxCGjhlpEFs7tg=
            - --email-domain=*
            - --provider-display-name=Keycloak
            - --cookie-expire=24h
          ports:
            - containerPort: 4180
              name: oauth2-proxy
              protocol: TCP
          resources: {}
    extraScrapeConfigs: |
      - job_name: 'karpenter'
        kubernetes_sd_configs:
          - role: endpoints
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_label_app_kubernetes_io_instance]
            action: keep
            regex: karpenter
        metrics_path: /metrics
        scheme: http
        static_configs:
          - targets: ['karpenter.kube-system.svc:8000']
    EOF
  ]

  depends_on = [
    kubernetes_namespace.grafana
  ]

}

# Prometheus dns name

resource "aws_route53_record" "prometheus" {
  count   = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  zone_id = var.zone_id
  name    = var.prometheus["dns_name"]
  type    = "A"

  alias {
    name                   = data.aws_lb.ingress[0].dns_name
    zone_id                = data.aws_lb.ingress[0].zone_id
    evaluate_target_health = false
  }
}

# Prometheus ingress

resource "kubernetes_ingress_v1" "prometheus" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  metadata {
    name        = "prometheus"
    namespace   = "grafana"
    annotations = local.ingress_annotations
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.prometheus["dns_name"]

      http {
        path {
          path = "/*"

          backend {
            service {
              name = "prometheus-server"
              port {
                number = 4180
              }
            }
          }

        }
      }
    }

    tls {
      hosts = [var.prometheus["dns_name"]]
    }
  }
}

# Grafana helm chart

resource "helm_release" "grafana" {
  count      = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  name       = "grafana"
  chart      = "grafana"
  version    = "8.8.2"
  repository = "https://grafana.github.io/helm-charts"
  namespace  = "grafana"

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = var.grafana["pv_storage"]
  }

  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "adminPassword"
    value = var.grafana_password
  }

  set {
    name  = "initChownData.enabled"
    value = "false"
  }

  set {
    name  = "assertNoLeakedSecrets"
    value = "false"
  }

  values = [
    <<EOF
persistence:
  accessModes: ["${var.grafana["pv_access_mode"]}"]
tolerations:
- key: "priority"
  operator: "Equal"
  value: "critical"
  effect: "NoSchedule"
nodeSelector:
  priority: "critical"
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-server.grafana
        access: proxy
        isDefault: true
dashboardProviders:
    dashboardproviders.yaml:
        apiVersion: 1
        providers:
        - name: 'default'
          orgId: 1
          folder: ''
          type: file
          disableDeletion: false
          editable: true
          options:
            path: /var/lib/grafana/dashboards/default
dashboards:
  default:
    kubernetes-dashboard:
      json: |
        ${indent(8, file("${path.module}/dashboard.json"))}
grafana.ini:
  server:
    domain: "${var.grafana["dns_name"]}"
    root_url: "https://${var.grafana["dns_name"]}"
  auth.generic_oauth:
    enabled: true
    name: Keycloak
    allow_sign_up: true
    scopes: openid,${keycloak_openid_client_scope.grafana_client_scope[0].name}
    client_id: ${keycloak_openid_client.openid_client_grafana[0].client_id}
    client_secret: ${keycloak_openid_client.openid_client_grafana[0].client_secret}
    auth_url: https://${var.keycloak["dns_name"]}/realms/${keycloak_realm.realm[0].id}/protocol/openid-connect/auth
    token_url: https://${var.keycloak["dns_name"]}/realms/${keycloak_realm.realm[0].id}/protocol/openid-connect/token
    api_url: https://${var.keycloak["dns_name"]}/realms/${keycloak_realm.realm[0].id}/protocol/openid-connect/userinfo
    role_attribute_path: contains(groups[*], '${keycloak_group.admins[0].name}') && 'Admin' || contains(groups[*], '${keycloak_group.software_developers[0].name}') && 'Editor'  
alerting: 
  contactpoints.yaml:
    secret:
      apiVersion: 1
      contactPoints:
        - orgId: 1
          name: slack_alerts
          receivers:
            - uid: slack
              type: slack
              settings:
                url: "${var.slack_incoming_webhook_url}"
  policies.yaml:
    policies:
      - orgId: 1
        receiver: slack_alerts
        group_by: ["..."]
EOF
  ]

}

# Grafana dns name

resource "aws_route53_record" "grafana" {
  count   = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  zone_id = var.zone_id
  name    = var.grafana["dns_name"]
  type    = "A"

  alias {
    name                   = data.aws_lb.ingress[0].dns_name
    zone_id                = data.aws_lb.ingress[0].zone_id
    evaluate_target_health = false
  }
}

# Grafana ingress

resource "kubernetes_ingress_v1" "grafana" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  metadata {
    name        = "grafana"
    namespace   = "grafana"
    annotations = local.ingress_annotations
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.grafana["dns_name"]

      http {
        path {
          path = "/*"

          backend {
            service {
              name = "grafana"
              port {
                number = 80
              }
            }
          }

        }
      }
    }

    tls {
      hosts = [var.grafana["dns_name"]]
    }
  }
}

# Grafana Keycloak
# https://medium.com/@charled.breteche/securing-grafana-with-keycloak-sso-d01fec05d984

resource "keycloak_openid_client" "openid_client_grafana" {
  count                           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id                        = keycloak_realm.realm[0].id
  client_id                       = "grafana"
  name                            = "grafana"
  enabled                         = true
  access_type                     = "CONFIDENTIAL"
  standard_flow_enabled           = true
  valid_redirect_uris             = ["https://${var.grafana["dns_name"]}/login/generic_oauth"]
  root_url                        = "https://${var.grafana["dns_name"]}"
  web_origins                     = ["https://${var.grafana["dns_name"]}"]
  admin_url                       = "https://${var.grafana["dns_name"]}"
  base_url                        = "https://${var.grafana["dns_name"]}"
  valid_post_logout_redirect_uris = ["+"]
  direct_access_grants_enabled    = true
}

resource "keycloak_openid_client_scope" "grafana_client_scope" {
  count                  = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id               = keycloak_realm.realm[0].id
  name                   = "grafana_client_scope"
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "groups" {
  count           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id        = keycloak_realm.realm[0].id
  client_scope_id = keycloak_openid_client_scope.grafana_client_scope[0].id
  name            = "groups"
  claim_name      = "groups"
  full_path       = false
}

resource "keycloak_generic_protocol_mapper" "email_grafana" {
  count           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id        = keycloak_realm.realm[0].id
  client_scope_id = keycloak_openid_client_scope.grafana_client_scope[0].id
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

resource "keycloak_openid_client_default_scopes" "client_default_scopes_grafana" {
  count          = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id       = keycloak_realm.realm[0].id
  client_id      = keycloak_openid_client.openid_client_grafana[0].id
  default_scopes = ["profile", "email", keycloak_openid_client_scope.grafana_client_scope[0].name]
}

# Prometheus Keycloak

resource "keycloak_openid_client" "openid_client_prometheus" {
  count                           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id                        = keycloak_realm.realm[0].id
  client_id                       = "prometheus"
  name                            = "prometheus"
  enabled                         = true
  access_type                     = "CONFIDENTIAL"
  standard_flow_enabled           = true
  valid_redirect_uris             = ["https://${var.prometheus["dns_name"]}/oauth2/callback"]
  root_url                        = "https://${var.prometheus["dns_name"]}"
  web_origins                     = ["https://${var.prometheus["dns_name"]}"]
  admin_url                       = "https://${var.prometheus["dns_name"]}"
  base_url                        = "https://${var.prometheus["dns_name"]}"
  valid_post_logout_redirect_uris = ["+"]
  direct_access_grants_enabled    = true
}

resource "keycloak_openid_client_scope" "prometheus_client_scope" {
  count                  = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id               = keycloak_realm.realm[0].id
  name                   = "prometheus_client_scope"
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "prometheus_groups" {
  count           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id        = keycloak_realm.realm[0].id
  client_scope_id = keycloak_openid_client_scope.prometheus_client_scope[0].id
  name            = "groups"
  claim_name      = "groups"
  full_path       = false
}

resource "keycloak_generic_protocol_mapper" "email_prometheus" {
  count           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id        = keycloak_realm.realm[0].id
  client_scope_id = keycloak_openid_client_scope.prometheus_client_scope[0].id
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

resource "keycloak_openid_client_default_scopes" "client_default_scopes_prometheus" {
  count          = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id       = keycloak_realm.realm[0].id
  client_id      = keycloak_openid_client.openid_client_prometheus[0].id
  default_scopes = ["profile", "email", keycloak_openid_client_scope.prometheus_client_scope[0].name]
}

resource "kubernetes_namespace" "ns" {
  count = var.cluster_created ? 1 : 0
  metadata {
    name = "argocd"
  }
}

# Argo helm chart
resource "helm_release" "argocd" {
  count      = var.cluster_created ? 1 : 0
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = "7.1.2"

  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  set {
    name  = "notifications.secret.create"
    value = false
  }

  set {
    name  = "notifications.cm.create"
    value = false
  }

  set {
    name  = "notifications.containerPorts.metrics"
    value = 9002
  }

  values = [
    <<EOT
configs:
  cm:
    "timeout.reconciliation": "60s"
    "url": "https://${var.argocd["dns_name"]}"
    "oidc.config": |
      name: Keycloak
      issuer: https://${var.keycloak["dns_name"]}/realms/${var.keycloak["realm_name"]}
      clientID: ${keycloak_openid_client.openid_client_argocd[0].client_id}
      clientSecret: ${keycloak_openid_client.openid_client_argocd[0].client_secret}
      requestedScopes: ["${keycloak_openid_client_scope.argocd_client_scope[0].name}","openid"]
  rbac:
    "policy.default": "deny"
    "scopes": '[groups]'
    "policy.csv": |
      g, ${keycloak_group.admins[0].name}, role:admin
      g, ${keycloak_group.software_developers[0].name}, role:readonly
  secret:
    extra:
      oidc.keycloak.clientSecret: ${keycloak_openid_client.openid_client_argocd[0].client_secret}
EOT
  ]
}

# Ingress dns name

resource "aws_route53_record" "ingress-elb" {
  count   = var.cluster_created ? 1 : 0
  zone_id = var.zone_id
  name    = var.argocd["dns_name"]
  type    = "A"

  alias {
    name                   = data.aws_lb.ingress[0].dns_name
    zone_id                = data.aws_lb.ingress[0].zone_id
    evaluate_target_health = false
  }
}

# Ingress

#kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
resource "kubernetes_ingress_v1" "ingress" {
  count = var.cluster_created ? 1 : 0
  metadata {
    name      = "argocd"
    namespace = "argocd"
    annotations = merge(
      local.ingress_annotations,
      {
        "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      }
    )
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.argocd["dns_name"]

      http {
        path {
          path = "/*"

          backend {
            service {
              name = "argo-cd-argocd-server"
              port {
                number = 443
              }
            }
          }

        }
      }
    }

    tls {
      hosts = [var.argocd["dns_name"]]
    }
  }
}

# Argo ssh auth

resource "kubernetes_secret" "argo-secret" {
  count = var.cluster_created ? 1 : 0
  metadata {
    name      = "private-repo"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  type = "Opaque"

  data = {
    "type"          = "git"
    "url"           = var.argocd["repo"]
    "sshPrivateKey" = var.argocd_ssh_private_key
  }
}

# Argo notifications secret

resource "kubernetes_secret" "argocd_notifications_secret" {
  count = var.cluster_created ? 1 : 0
  metadata {
    name      = "argocd-notifications-secret"
    namespace = "argocd"
  }

  data = {
    "slack-token" = var.argocd_slack_token
  }

  type = "Opaque"
}

# Argo notifications

resource "kubernetes_config_map" "argocd_notifications_cm" {
  count = var.cluster_created ? 1 : 0
  metadata {
    name      = "argocd-notifications-cm"
    namespace = "argocd"
  }

  data = {
    "service.slack" = <<-EOT
      token: $slack-token
    EOT

    "context" = <<-EOT
      argocdUrl: https://${var.argocd["dns_name"]}
    EOT

    "trigger.on-health-degraded" = <<-EOT
      - when: app.status.health.status == 'Degraded' || app.status.health.status == 'Missing' || app.status.health.status == 'Unknown'
        send: [app-degraded]
    EOT

    "template.app-degraded" = <<-EOT
      message: |
        ArgoCD - Application {{.app.metadata.name}} is {{.app.status.health.status}}.
      slack:
        attachments: |
          [{
            "title": "{{.app.metadata.name}}",
            "title_link": "{{.context.argocdUrl}}/applications/argocd/{{.app.metadata.name}}",
            "color": "#ff0000",
            "fields": [{
              "title": "App Health",
              "value": "{{.app.status.health.status}}",
              "short": true
            }, {
              "title": "Repository",
              "value": "{{.app.spec.source.repoURL}}",
              "short": true
            }]
          }]
    EOT
  }
}

# Image updater

resource "helm_release" "image_updater" {
  count      = var.cluster_created ? 1 : 0
  name       = "argocd-image-updater"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  namespace  = "argocd"
  version    = "0.10.1"
  values     = var.argocd_image_updater_values
}

# Keycloak
# https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/keycloak/
# https://www.youtube.com/watch?v=_72InRW4bdU

resource "keycloak_openid_client" "openid_client_argocd" {
  count                           = var.cluster_created ? 1 : 0
  realm_id                        = keycloak_realm.realm[0].id
  client_id                       = "argocd"
  name                            = "argocd"
  access_type                     = "CONFIDENTIAL"
  standard_flow_enabled           = true
  direct_access_grants_enabled    = true
  root_url                        = "https://${var.argocd["dns_name"]}"
  valid_redirect_uris             = ["https://${var.argocd["dns_name"]}/auth/callback"]
  web_origins                     = ["https://${var.argocd["dns_name"]}"]
  admin_url                       = "https://${var.argocd["dns_name"]}"
  valid_post_logout_redirect_uris = ["+"]
}

resource "keycloak_openid_client_scope" "argocd_client_scope" {
  count                  = var.cluster_created ? 1 : 0
  realm_id               = keycloak_realm.realm[0].id
  name                   = "argocd_client_scope"
  description            = "When requested, this scope will map a user's group memberships to a claim"
  include_in_token_scope = true
}

resource "keycloak_generic_protocol_mapper" "group_membership" {
  count           = var.cluster_created ? 1 : 0
  realm_id        = keycloak_realm.realm[0].id
  client_scope_id = keycloak_openid_client_scope.argocd_client_scope[0].id
  name            = "group_membership"
  protocol        = "openid-connect"
  protocol_mapper = "oidc-group-membership-mapper"
  config = {
    "access.token.claim"        = "true"
    "id.token.claim"            = "true"
    "userinfo.token.claim"      = "true"
    "full.path"                 = "false"
    "claim.name"                = "groups"
    "jsonType.label"            = "String"
    "introspection.token.claim" = "false"
    "lightweight.claim"         = "false"
    "multivalued"               = "true"
  }
}

resource "keycloak_generic_protocol_mapper" "email" {
  count           = var.cluster_created ? 1 : 0
  realm_id        = keycloak_realm.realm[0].id
  client_scope_id = keycloak_openid_client_scope.argocd_client_scope[0].id
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

resource "keycloak_generic_protocol_mapper" "groups" {
  count           = var.cluster_created ? 1 : 0
  realm_id        = keycloak_realm.realm[0].id
  client_scope_id = keycloak_openid_client_scope.argocd_client_scope[0].id
  name            = "groups"
  protocol        = "openid-connect"
  protocol_mapper = "oidc-usermodel-realm-role-mapper"
  config = {
    "access.token.claim"        = "true"
    "id.token.claim"            = "true"
    "userinfo.token.claim"      = "true"
    "full.path"                 = "false"
    "claim.name"                = "groups"
    "jsonType.label"            = "String"
    "introspection.token.claim" = "false"
    "lightweight.claim"         = "false"
    "multivalued"               = "false"
    "multivalued"               = "true"
  }
}

resource "keycloak_openid_client_default_scopes" "client_default_scopes_argocd" {
  count          = var.cluster_created ? 1 : 0
  realm_id       = keycloak_realm.realm[0].id
  client_id      = keycloak_openid_client.openid_client_argocd[0].id
  default_scopes = [keycloak_openid_client_scope.argocd_client_scope[0].name]
}

# ELK namespace

resource "kubernetes_namespace" "elk" {
  count = var.cluster_created && var.logs_type == "elk" ? 1 : 0
  metadata {
    name = "elk"
  }
}

# Elasticsearch helm chart

resource "helm_release" "elastic" {
  count      = var.cluster_created && var.logs_type == "elk" ? 1 : 0
  name       = "elasticsearch"
  chart      = "elasticsearch"
  version    = "8.5.1"
  repository = "https://helm.elastic.co"
  namespace  = "elk"

  set {
    name  = "replicas"
    value = var.elastic["replicas"]
  }

  set {
    name  = "minimumMasterNodes"
    value = var.elastic["minimumMasterNodes"]
  }

  set {
    name  = "volumeClaimTemplate.resources.requests.storage"
    value = var.elastic["pv_storage"]
  }

  set {
    name  = "createCert"
    value = "true"
  }

  set {
    name  = "protocol"
    value = "https"
  }

  set {
    name  = "secret.password"
    value = var.elastic_password
  }

  values = [
    <<EOF
    esConfig:
      elasticsearch.yml: |
        xpack.security.enabled: true
    volumeClaimTemplate:
      accessModes: ["${var.elastic["pv_access_mode"]}"]
    resources: 
      requests:
        cpu: "100m"
        memory: "1.5Gi"
      limits:
        cpu: "1000m"
        memory: "2.5Gi"
    tolerations:
    - key: "priority"
      operator: "Equal"
      value: "critical"
      effect: "NoSchedule"
    nodeSelector:
      priority: "critical"
    EOF
  ]

  depends_on = [
    kubernetes_namespace.elk
  ]

}

# Kibana dns name

resource "aws_route53_record" "kibana" {
  count   = var.cluster_created && var.logs_type == "elk" ? 1 : 0
  zone_id = var.zone_id
  name    = var.kibana["dns_name"]
  type    = "A"

  alias {
    name                   = data.aws_lb.ingress[0].dns_name
    zone_id                = data.aws_lb.ingress[0].zone_id
    evaluate_target_health = false
  }
}

# Kibana helm chart

resource "helm_release" "kibana" {
  count      = var.cluster_created && var.logs_type == "elk" ? 1 : 0
  name       = "kibana"
  chart      = "kibana"
  version    = "8.5.1"
  repository = "https://helm.elastic.co"
  namespace  = "elk"

  set {
    name  = "elasticsearchHosts"
    value = "https://elasticsearch-master.elk:9200"
  }

  set {
    name  = "automountToken"
    value = false
  }

  set {
    name  = "service.type"
    value = "NodePort"
  }

  values = [
    <<EOF
    resources: 
      requests:
        cpu: "100m"
        memory: "1Gi"
      limits:
        cpu: "1000m"
        memory: "2Gi"
    tolerations:
    - key: "priority"
      operator: "Equal"
      value: "critical"
      effect: "NoSchedule"
    nodeSelector:
      priority: "critical"
    kibanaConfig:
      kibana.yml: |
        xpack.security.authc.providers:
          anonymous.anonymous1:
            order: 0
            credentials:
              username: "elastic"
              password: "${var.elastic_password}"
    EOF
  ]

  depends_on = [
    helm_release.elastic
  ]

}

# Kibana oauth2-proxy

resource "helm_release" "kibana_oauth2_proxy" {
  count      = var.cluster_created && var.logs_type == "elk" ? 1 : 0
  name       = "kibana-oauth2-proxy"
  chart      = "oauth2-proxy"
  version    = "7.10.2"
  repository = "https://oauth2-proxy.github.io/manifests"
  namespace  = "elk"

  set {
    name  = "service.type"
    value = "NodePort"
  }

  values = [
    <<EOF
    resources: 
      requests:
        cpu: "100m"
        memory: "256Mi"
      limits:
        cpu: "100m"
        memory: "256Mi"
    tolerations:
    - key: "priority"
      operator: "Equal"
      value: "critical"
      effect: "NoSchedule"
    nodeSelector:
      priority: "critical"
    config:
      clientID: ${keycloak_openid_client.openid_client_kibana[0].client_id}
      clientSecret: ${keycloak_openid_client.openid_client_kibana[0].client_secret}
      cookieSecret: "lZn0QCSAHMiSM9DTPkTQZhBTETPiQgxCGjhlpEFs7tg="
      configFile: |
          email_domains = [ "*" ]
          upstreams = [ "http://kibana-kibana.elk.svc:5601" ]
          cookie_secure = "true"
          provider = "oidc"
          http_address = "0.0.0.0:80"
          oidc_issuer_url = "https://${var.keycloak["dns_name"]}/realms/${var.keycloak["realm_name"]}"
          cookie_expire = "24h"
          provider_display_name = "Keycloak"
          scope = "openid ${keycloak_openid_client_scope.kibana_client_scope[0].name}"
          redirect_url = "https://${var.kibana["dns_name"]}/oauth2/callback"
    EOF
  ]

}

# Kibana ingress

resource "kubernetes_ingress_v1" "kibana" {
  count = var.cluster_created && var.logs_type == "elk" ? 1 : 0
  metadata {
    name        = "kibana"
    namespace   = "elk"
    annotations = local.ingress_annotations
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.kibana["dns_name"]

      http {
        path {
          path = "/*"

          backend {
            service {
              name = "kibana-oauth2-proxy"
              port {
                number = 80
              }
            }
          }

        }
      }
    }

    tls {
      hosts = [var.kibana["dns_name"]]
    }
  }
}

# Logstash helm chart

resource "helm_release" "logstash" {
  count      = var.cluster_created && var.logs_type == "elk" ? 1 : 0
  name       = "logstash"
  chart      = "logstash"
  version    = "8.5.1"
  repository = "https://helm.elastic.co"
  namespace  = "elk"

  set {
    name  = "replicas"
    value = 2
  }

  values = [
    <<EOF
    logstashConfig:
      logstash.yml: |
        http.host: 0.0.0.0
        xpack.monitoring.enabled: false
    logstashPipeline: 
      logstash.conf: |
        input {
          beats {
            port => 5044
          }
        }
        filter {
        }
        output {
          elasticsearch {
            hosts => "https://elasticsearch-master.elk:9200"
            ssl_certificate_verification => false
            user => "elastic"
            password => "${var.elastic_password}"
            manage_template => false
            index => "%%{[@metadata][beat]}-%%{+YYYY.MM.dd}"
            document_type => "%%{[@metadata][type]}"
          }
        }
    service:
      type: ClusterIP
      ports:
        - name: beats
          port: 5044
          protocol: TCP
          targetPort: 5044
        - name: http
          port: 8080
          protocol: TCP
          targetPort: 8080
    resources: 
      requests:
        cpu: "100m"
        memory: "1Gi"
      limits:
        cpu: "1024m"
        memory: "2Gi"
    tolerations:
    - key: "priority"
      operator: "Equal"
      value: "critical"
      effect: "NoSchedule"
    nodeSelector:
      priority: "critical"
    EOF
  ]

  depends_on = [
    helm_release.elastic
  ]
}

# Filebeat helm chart

resource "helm_release" "filebeat" {
  count      = var.cluster_created && var.logs_type == "elk" ? 1 : 0
  name       = "filebeat"
  chart      = "filebeat"
  version    = "8.5.1"
  repository = "https://helm.elastic.co"
  namespace  = "elk"

  values = [
    <<EOF
    filebeatConfig:
        filebeat.yml: |
            filebeat.inputs:
            - type: container
              paths:
                - /var/log/containers/*.log
              processors:
              - add_kubernetes_metadata:
                    host: $${NODE_NAME}
                    matchers:
                    - logs_path:
                        logs_path: "/var/log/containers/"

            output.logstash:
                hosts: ["logstash-logstash.elk:5044"]
    resources: 
      requests:
        cpu: "100m"
        memory: "100Mi"
      limits:
        cpu: "1024m"
        memory: "1000Mi"
    tolerations:
    - key: "priority"
      operator: "Equal"
      value: "critical"
      effect: "NoSchedule"
    EOF
  ]

  depends_on = [
    helm_release.logstash
  ]

}

# Kibana Keycloak

resource "keycloak_openid_client" "openid_client_kibana" {
  count                           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id                        = keycloak_realm.realm[0].id
  client_id                       = "kibana"
  name                            = "kibana"
  enabled                         = true
  access_type                     = "CONFIDENTIAL"
  standard_flow_enabled           = true
  valid_redirect_uris             = ["https://${var.kibana["dns_name"]}/oauth2/callback"]
  root_url                        = "https://${var.kibana["dns_name"]}"
  web_origins                     = ["https://${var.kibana["dns_name"]}"]
  admin_url                       = "https://${var.kibana["dns_name"]}"
  base_url                        = "https://${var.kibana["dns_name"]}"
  valid_post_logout_redirect_uris = ["+"]
  direct_access_grants_enabled    = true
}

resource "keycloak_openid_client_scope" "kibana_client_scope" {
  count                  = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id               = keycloak_realm.realm[0].id
  name                   = "kibana_client_scope"
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "kibana_groups" {
  count           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id        = keycloak_realm.realm[0].id
  client_scope_id = keycloak_openid_client_scope.kibana_client_scope[0].id
  name            = "groups"
  claim_name      = "groups"
  full_path       = false
}

resource "keycloak_generic_protocol_mapper" "kibana_email" {
  count           = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id        = keycloak_realm.realm[0].id
  client_scope_id = keycloak_openid_client_scope.kibana_client_scope[0].id
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

resource "keycloak_openid_client_default_scopes" "client_default_scopes_kibana" {
  count          = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  realm_id       = keycloak_realm.realm[0].id
  client_id      = keycloak_openid_client.openid_client_kibana[0].id
  default_scopes = ["profile", "email", keycloak_openid_client_scope.kibana_client_scope[0].name]
}

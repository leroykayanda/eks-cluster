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
                number = 80
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
  version    = "7.3.11"
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
    root_url: "%(protocol)s://%(domain)s/"
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

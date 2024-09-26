# ELK namespace

resource "kubernetes_namespace" "elk" {
  count = var.cluster_created && var.logs_type == "elk" ? 1 : 0
  metadata {
    name = "elk"
  }
}

# ELK helm chart

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
    EOF
  ]

  depends_on = [
    helm_release.elastic
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
              name = "kibana-kibana"
              port {
                number = 5601
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

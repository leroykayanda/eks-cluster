# Scalyr namespace

resource "kubernetes_namespace" "scalyr" {
  count = var.cluster_created && var.set_up_scalyr ? 1 : 0
  metadata {
    name = "scalyr"
  }
}

# Scalyr helm chart

resource "helm_release" "scalyr" {
  count      = var.cluster_created && var.set_up_scalyr ? 1 : 0
  name       = "scalyr"
  chart      = "scalyr-agent"
  version    = "0.2.45"
  repository = "https://scalyr.github.io/helm-scalyr/"
  namespace  = "scalyr"

  set {
    name  = "scalyr.apiKey"
    value = var.scalyr_api_key
  }

  set {
    name  = "scalyr.k8s.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "fullnameOverride"
    value = var.cluster_name
  }

  values = [
    <<EOF
    resources: 
      requests:
        cpu: "500m"
        memory: "500Mi"
      limits:
        cpu: "1000m"
        memory: "1000Gi"
    tolerations:
    - key: "priority"
      operator: "Equal"
      value: "critical"
      effect: "NoSchedule"
    EOF
  ]

  depends_on = [
    kubernetes_namespace.scalyr
  ]

}

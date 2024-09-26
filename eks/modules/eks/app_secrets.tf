#https://www.giantswarm.io/blog/manage-kubernetes-secrets-using-aws-secrets-manager
resource "helm_release" "secrets" {
  count      = var.cluster_created ? 1 : 0
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "kube-system"
}

resource "helm_release" "reloader" {
  count      = var.cluster_created ? 1 : 0
  name       = "reloader"
  repository = "https://stakater.github.io/stakater-charts"
  chart      = "reloader"
  namespace  = "kube-system"

  set {
    name  = "reloader.reloadStrategy"
    value = "annotations"
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.8.0"

  set {
    name  = "loki.persistence.enabled"
    value = "true"
  }

  set {
    name  = "loki.persistence.storageClassName"
    value = "gp2"
  }

  set {
    name  = "loki.persistence.size"
    value = "10Gi"
  }

  set {
    name  = "loki.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "loki.service.port"
    value = "3100"
  }

  set {
    name  = "loki.ingress.enabled"
    value = "false"
  }

  depends_on = [helm_release.prometheus]
}
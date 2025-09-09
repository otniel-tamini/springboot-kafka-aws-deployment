resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "6.16.0"

  namespace = "monitoring"

  values = [
    templatefile("${path.module}/grafana-values.yaml", {
      admin_password = var.grafana_admin_password
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

output "grafana_url" {
  value = "http://${helm_release.grafana.name}.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local"
}
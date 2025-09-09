resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "16.0.0"

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelector.matchLabels"
    value = "app: my-app"
  }

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelector.matchExpressions[0].key"
    value = "app"
  }

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelector.matchExpressions[0].operator"
    value = "In"
  }

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelector.matchExpressions[0].values[0]"
    value = "my-app"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "256Mi"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.memory"
    value = "512Mi"
  }

  depends_on = [helm_release.grafana]
}
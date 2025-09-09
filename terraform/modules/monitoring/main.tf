# =================================
# MONITORING MODULE
# =================================

# Namespace for monitoring
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"

    labels = {
      name = "monitoring"
    }
  }
}

# Prometheus Operator using Helm
resource "helm_release" "prometheus_operator" {
  name       = "prometheus-operator"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "51.2.0"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
          retention = "30d"
        }
      }

      grafana = {
        adminPassword = "admin123"
        persistence = {
          enabled = true
          size    = "10Gi"
        }
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
          }
        }
      }

      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# Loki for log aggregation
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "2.9.11"

  values = [
    yamlencode({
      loki = {
        persistence = {
          enabled = true
          size    = "50Gi"
        }
        config = {
          schema_config = {
            configs = [
              {
                from         = "2020-10-24"
                store        = "boltdb-shipper"
                object_store = "filesystem"
                schema       = "v11"
                index = {
                  prefix = "index_"
                  period = "24h"
                }
              }
            ]
          }
        }
      }

      promtail = {
        enabled = true
        config = {
          logLevel   = "info"
          serverPort = 3101
          clients = [
            {
              url = "http://loki:3100/loki/api/v1/push"
            }
          ]
        }
      }

      fluent-bit = {
        enabled = false
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# ServiceMonitor for Spring Boot applications
resource "kubernetes_manifest" "spring_boot_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "spring-boot-apps"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        app = "spring-boot-monitoring"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "monitoring" = "enabled"
        }
      }
      endpoints = [
        {
          port     = "actuator"
          path     = "/actuator/prometheus"
          interval = "30s"
        }
      ]
      namespaceSelector = {
        matchNames = ["default"]
      }
    }
  }

  depends_on = [helm_release.prometheus_operator]
}

# ConfigMap for Grafana dashboards
resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "spring-boot-dashboard"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "spring-boot-dashboard.json" = jsonencode({
      dashboard = {
        id            = null
        title         = "Spring Boot Microservices"
        uid           = "spring-boot-microservices"
        version       = 1
        schemaVersion = 16

        panels = [
          {
            id    = 1
            title = "HTTP Requests per Second"
            type  = "graph"
            targets = [
              {
                expr         = "rate(http_requests_total[5m])"
                legendFormat = "{{service}}"
              }
            ]
            gridPos = {
              h = 8
              w = 12
              x = 0
              y = 0
            }
          },
          {
            id    = 2
            title = "JVM Memory Usage"
            type  = "graph"
            targets = [
              {
                expr         = "jvm_memory_used_bytes{area=\"heap\"}"
                legendFormat = "{{service}} - Heap"
              }
            ]
            gridPos = {
              h = 8
              w = 12
              x = 12
              y = 0
            }
          }
        ]

        time = {
          from = "now-1h"
          to   = "now"
        }

        refresh = "5s"
      }
    })
  }

  depends_on = [helm_release.prometheus_operator]
}

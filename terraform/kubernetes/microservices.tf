# =================================
# KUBERNETES DEPLOYMENTS MODULE
# =================================

# Create namespace for the application
resource "kubernetes_namespace" "app" {
  metadata {
    name = "default"
    
    labels = {
      name = "application"
    }
  }
}

# ConfigMap for shared configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    # Eureka configuration
    "EUREKA_DEFAULT_ZONE" = "http://eureka-server:8761/eureka/"
    
    # Kafka configuration
    "SPRING_KAFKA_BOOTSTRAP_SERVERS" = var.kafka_bootstrap_servers
    
    # Redis configuration
    "SPRING_REDIS_HOST" = var.redis_endpoint
    "SPRING_REDIS_PORT" = tostring(var.redis_port)
    "SPRING_REDIS_TIMEOUT" = "60000"
    
    # Database configuration
    "DB_USERNAME" = "root"
    
    # Spring profiles
    "SPRING_PROFILES_ACTIVE" = "k8s"
    
    # Zipkin configuration
    "ZIPKIN_BASE_URL" = "http://zipkin:9411/"
    "TRACING_SAMPLING_PROBABILITY" = "1.0"
  }
}

# Secret for database passwords
resource "kubernetes_secret" "db_passwords" {
  metadata {
    name      = "db-passwords"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    "ORDER_DB_PASSWORD"    = base64encode(var.database_passwords.order_db)
    "IDENTITY_DB_PASSWORD" = base64encode(var.database_passwords.identity_db)
    "PAYMENT_DB_PASSWORD"  = base64encode(var.database_passwords.payment_db)
    "PRODUCT_DB_PASSWORD"  = base64encode(var.database_passwords.product_db)
  }
}

# Service Registry (Eureka Server) Deployment
resource "kubernetes_deployment" "eureka_server" {
  metadata {
    name      = "eureka-server"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = {
      app = "eureka-server"
    }
  }

  spec {
    replicas = var.microservices.service_registry.replicas

    selector {
      match_labels = {
        app = "eureka-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "eureka-server"
          monitoring = "enabled"
        }
      }

      spec {
        container {
          image = "${var.project_name}/service-registry:${var.microservices.service_registry.image_tag}"
          name  = "eureka-server"

          port {
            container_port = var.microservices.service_registry.port
            name          = "http"
          }

          port {
            container_port = 8080
            name          = "actuator"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          env {
            name  = "EUREKA_PORT"
            value = tostring(var.microservices.service_registry.port)
          }

          resources {
            requests = {
              cpu    = var.microservices.service_registry.cpu_request
              memory = var.microservices.service_registry.memory_request
            }
            limits = {
              cpu    = var.microservices.service_registry.cpu_limit
              memory = var.microservices.service_registry.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = var.microservices.service_registry.health_check_path
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 30
          }

          readiness_probe {
            http_get {
              path = var.microservices.service_registry.health_check_path
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# Service for Eureka Server
resource "kubernetes_service" "eureka_server" {
  metadata {
    name      = "eureka-server"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = {
      app = "eureka-server"
      monitoring = "enabled"
    }
  }

  spec {
    selector = {
      app = "eureka-server"
    }

    port {
      name        = "http"
      port        = var.microservices.service_registry.port
      target_port = var.microservices.service_registry.port
    }

    port {
      name        = "actuator"
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

# API Gateway Deployment
resource "kubernetes_deployment" "api_gateway" {
  metadata {
    name      = "api-gateway"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = {
      app = "api-gateway"
    }
  }

  spec {
    replicas = var.microservices.api_gateway.replicas

    selector {
      match_labels = {
        app = "api-gateway"
      }
    }

    template {
      metadata {
        labels = {
          app = "api-gateway"
          monitoring = "enabled"
        }
      }

      spec {
        container {
          image = "${var.project_name}/api-gateway:${var.microservices.api_gateway.image_tag}"
          name  = "api-gateway"

          port {
            container_port = var.microservices.api_gateway.port
            name          = "http"
          }

          port {
            container_port = 8080
            name          = "actuator"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          env {
            name  = "API_GATEWAY_PORT"
            value = tostring(var.microservices.api_gateway.port)
          }

          resources {
            requests = {
              cpu    = var.microservices.api_gateway.cpu_request
              memory = var.microservices.api_gateway.memory_request
            }
            limits = {
              cpu    = var.microservices.api_gateway.cpu_limit
              memory = var.microservices.api_gateway.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = var.microservices.api_gateway.health_check_path
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 30
          }

          readiness_probe {
            http_get {
              path = var.microservices.api_gateway.health_check_path
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.eureka_server]
}

# Service for API Gateway
resource "kubernetes_service" "api_gateway" {
  metadata {
    name      = "api-gateway"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = {
      app = "api-gateway"
      monitoring = "enabled"
    }
  }

  spec {
    selector = {
      app = "api-gateway"
    }

    port {
      name        = "http"
      port        = var.microservices.api_gateway.port
      target_port = var.microservices.api_gateway.port
    }

    port {
      name        = "actuator"
      port        = 8080
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

# Order Service Deployment
resource "kubernetes_deployment" "order_service" {
  metadata {
    name      = "order-service"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = {
      app = "order-service"
    }
  }

  spec {
    replicas = var.microservices.order_service.replicas

    selector {
      match_labels = {
        app = "order-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "order-service"
          monitoring = "enabled"
        }
      }

      spec {
        container {
          image = "${var.project_name}/order-service:${var.microservices.order_service.image_tag}"
          name  = "order-service"

          port {
            container_port = var.microservices.order_service.port
            name          = "http"
          }

          port {
            container_port = 8080
            name          = "actuator"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          env {
            name  = "ORDER_SERVICE_PORT"
            value = tostring(var.microservices.order_service.port)
          }

          env {
            name  = "SPRING_DATASOURCE_URL"
            value = "jdbc:mysql://${var.database_endpoints.order_db}:3306/order_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
          }

          env {
            name = "SPRING_DATASOURCE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_passwords.metadata[0].name
                key  = "ORDER_DB_PASSWORD"
              }
            }
          }

          resources {
            requests = {
              cpu    = var.microservices.order_service.cpu_request
              memory = var.microservices.order_service.memory_request
            }
            limits = {
              cpu    = var.microservices.order_service.cpu_limit
              memory = var.microservices.order_service.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = var.microservices.order_service.health_check_path
              port = 8080
            }
            initial_delay_seconds = 90
            period_seconds        = 30
          }

          readiness_probe {
            http_get {
              path = var.microservices.order_service.health_check_path
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 10
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.eureka_server]
}

# Service for Order Service
resource "kubernetes_service" "order_service" {
  metadata {
    name      = "order-service"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = {
      app = "order-service"
      monitoring = "enabled"
    }
  }

  spec {
    selector = {
      app = "order-service"
    }

    port {
      name        = "http"
      port        = var.microservices.order_service.port
      target_port = var.microservices.order_service.port
    }

    port {
      name        = "actuator"
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

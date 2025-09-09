# Makefile pour les microservices Spring Boot Kafka

.PHONY: help build start stop clean logs status urls

# Variables
COMPOSE_FILE = docker-compose.yml
ENV_FILE = .env

# Couleurs pour l'affichage
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Afficher cette aide
	@echo "$(GREEN)Commandes disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

check-env: ## Vérifier que le fichier .env existe
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)Erreur: Fichier .env introuvable!$(NC)"; \
		exit 1; \
	fi

build-jars: ## Construire les JARs Maven pour tous les services
	@echo "$(GREEN)Construction des JARs Maven...$(NC)"
	@for service in service-registry api-gateway order-service email-service payment-service product-service identity-service; do \
		if [ -d "$$service" ]; then \
			echo "$(YELLOW)Construction de $$service...$(NC)"; \
			cd $$service && (./mvnw clean package -DskipTests || mvn clean package -DskipTests) && cd ..; \
		fi; \
	done

build: check-env build-jars ## Construire tous les services avec Docker
	@echo "$(GREEN)Construction des images Docker...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) build

start: check-env ## Démarrer tous les services
	@echo "$(GREEN)Démarrage des services...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d

start-infra: check-env ## Démarrer seulement l'infrastructure (Kafka, MySQL, Redis)
	@echo "$(GREEN)Démarrage de l'infrastructure...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d zookeeper kafka redis mysql-order-service mysql-identity-service mysql-payment-service mysql-product-service

start-services: check-env ## Démarrer seulement les microservices
	@echo "$(GREEN)Démarrage des microservices...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d eureka-server api-gateway order-service email-service payment-service product-service identity-service

full-deploy: clean build start status urls ## Déploiement complet (clean + build + start)

stop: ## Arrêter tous les services
	@echo "$(YELLOW)Arrêt des services...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down

clean: ## Nettoyer les conteneurs et images
	@echo "$(YELLOW)Nettoyage...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down --remove-orphans
	@docker system prune -f
	@docker images | grep "springboot-kafka-microservices" | awk '{print $$3}' | xargs -r docker rmi -f 2>/dev/null || true

logs: ## Afficher les logs de tous les services
	@docker-compose -f $(COMPOSE_FILE) logs -f

logs-service: ## Afficher les logs d'un service spécifique (usage: make logs-service SERVICE=order-service)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Erreur: Spécifiez le service avec SERVICE=nom-du-service$(NC)"; \
		exit 1; \
	fi
	@docker-compose -f $(COMPOSE_FILE) logs -f $(SERVICE)

status: ## Afficher le statut des services
	@echo "$(GREEN)Statut des services:$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps

health: ## Vérifier la santé des services
	@echo "$(GREEN)Vérification de la santé des services:$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps --filter status=running

urls: ## Afficher les URLs des services
	@echo "$(GREEN)URLs des services:$(NC)"
	@echo "  Eureka Server:    http://localhost:8761"
	@echo "  API Gateway:      http://localhost:9191"
	@echo "  Order Service:    http://localhost:8080"
	@echo "  Email Service:    http://localhost:8086"
	@echo "  Payment Service:  http://localhost:8085"
	@echo "  Product Service:  http://localhost:8084"
	@echo "  Identity Service: http://localhost:9898"
	@echo ""
	@echo "$(GREEN)Infrastructure:$(NC)"
	@echo "  Kafka:            localhost:29092 (external), localhost:9092 (internal)"
	@echo "  Redis:            localhost:6379"
	@echo "  MySQL Order:      localhost:3307"
	@echo "  MySQL Identity:   localhost:3308"
	@echo "  MySQL Payment:    localhost:3309"
	@echo "  MySQL Product:    localhost:3310"

restart: stop start ## Redémarrer tous les services

restart-service: ## Redémarrer un service spécifique (usage: make restart-service SERVICE=order-service)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Erreur: Spécifiez le service avec SERVICE=nom-du-service$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Redémarrage de $(SERVICE)...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) restart $(SERVICE)

shell: ## Ouvrir un shell dans un conteneur (usage: make shell SERVICE=order-service)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Erreur: Spécifiez le service avec SERVICE=nom-du-service$(NC)"; \
		exit 1; \
	fi
	@docker-compose -f $(COMPOSE_FILE) exec $(SERVICE) /bin/sh

test-connectivity: ## Tester la connectivité entre les services
	@echo "$(GREEN)Test de connectivité...$(NC)"
	@echo "$(YELLOW)Test Eureka Server...$(NC)"
	@curl -s http://localhost:8761/actuator/health > /dev/null && echo "✓ Eureka OK" || echo "✗ Eureka KO"
	@echo "$(YELLOW)Test API Gateway...$(NC)"
	@curl -s http://localhost:9191/actuator/health > /dev/null && echo "✓ API Gateway OK" || echo "✗ API Gateway KO"

dev-setup: ## Configuration pour développement (build + start infra seulement)
	@echo "$(GREEN)Configuration développement...$(NC)"
	@make build-jars
	@make start-infra
	@echo "$(GREEN)Infrastructure prête pour le développement$(NC)"

prod-deploy: ## Déploiement production
	@echo "$(GREEN)Déploiement production...$(NC)"
	@make clean
	@make build
	@make start
	@sleep 30
	@make health
	@make urls

# Commande par défaut
.DEFAULT_GOAL := help

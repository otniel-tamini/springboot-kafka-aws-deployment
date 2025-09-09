#!/bin/bash

# Script de build et déploiement pour les microservices Spring Boot Kafka
set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function pour afficher des messages colorés
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Vérifier si Docker et Docker Compose sont installés
check_prerequisites() {
    print_step "Vérification des prérequis..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker n'est pas installé. Veuillez installer Docker."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose n'est pas installé. Veuillez installer Docker Compose."
        exit 1
    fi
    
    print_message "Prérequis OK"
}

# Nettoyer les anciens conteneurs et images
cleanup() {
    print_step "Nettoyage des anciens conteneurs et images..."
    
    # Arrêter et supprimer les conteneurs existants
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Supprimer les images du projet
    docker images | grep "springboot-kafka-microservices" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
    
    print_message "Nettoyage terminé"
}

# Builder les microservices individuellement
build_services() {
    print_step "Construction des microservices..."
    
    services=("service-registry" "api-gateway" "order-service" "email-service" "payment-service" "product-service" "identity-service")
    
    for service in "${services[@]}"; do
        if [ -d "$service" ]; then
            print_message "Construction de $service..."
            cd "$service"
            
            # Builder le JAR avec Maven
            if [ -f "mvnw" ]; then
                ./mvnw clean package -DskipTests
            else
                mvn clean package -DskipTests
            fi
            
            cd ..
            print_message "$service construit avec succès"
        else
            print_warning "Répertoire $service introuvable, passage au suivant"
        fi
    done
}

# Builder et démarrer avec Docker Compose
deploy() {
    print_step "Démarrage de l'infrastructure avec Docker Compose..."
    
    # Construire les images et démarrer les services
    docker-compose up --build -d
    
    print_message "Déploiement terminé"
}

# Afficher le statut des services
show_status() {
    print_step "Statut des services:"
    docker-compose ps
    
    print_step "Logs récents:"
    docker-compose logs --tail=10
}

# Afficher les URLs des services
show_urls() {
    print_step "URLs des services:"
    echo -e "${GREEN}Eureka Server:${NC} http://localhost:8761"
    echo -e "${GREEN}API Gateway:${NC} http://localhost:9191"
    echo -e "${GREEN}Order Service:${NC} http://localhost:8080"
    echo -e "${GREEN}Email Service:${NC} http://localhost:8086"
    echo -e "${GREEN}Payment Service:${NC} http://localhost:8085"
    echo -e "${GREEN}Product Service:${NC} http://localhost:8084"
    echo -e "${GREEN}Identity Service:${NC} http://localhost:9898"
    echo ""
    echo -e "${GREEN}Kafka UI (si installé):${NC} http://localhost:8080"
    echo -e "${GREEN}Redis Commander (si installé):${NC} http://localhost:8081"
}

# Menu principal
show_menu() {
    echo ""
    echo -e "${BLUE}=== Script de Déploiement Microservices ===${NC}"
    echo "1. Build complet et déploiement"
    echo "2. Déploiement seulement"
    echo "3. Arrêter les services"
    echo "4. Nettoyer"
    echo "5. Afficher le statut"
    echo "6. Afficher les logs"
    echo "7. Afficher les URLs"
    echo "8. Quitter"
    echo ""
}

# Fonction principale
main() {
    while true; do
        show_menu
        read -p "Choisissez une option (1-8): " choice
        
        case $choice in
            1)
                check_prerequisites
                cleanup
                build_services
                deploy
                show_status
                show_urls
                ;;
            2)
                check_prerequisites
                deploy
                show_status
                show_urls
                ;;
            3)
                print_step "Arrêt des services..."
                docker-compose down
                print_message "Services arrêtés"
                ;;
            4)
                cleanup
                ;;
            5)
                show_status
                ;;
            6)
                print_step "Logs des services:"
                docker-compose logs -f
                ;;
            7)
                show_urls
                ;;
            8)
                print_message "Au revoir!"
                exit 0
                ;;
            *)
                print_error "Option invalide. Veuillez choisir entre 1 et 8."
                ;;
        esac
        
        echo ""
        read -p "Appuyez sur Entrée pour continuer..."
    done
}

# Exécuter le script principal
main

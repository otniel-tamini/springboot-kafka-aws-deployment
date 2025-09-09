#!/bin/bash

echo "🔨 Construction des JARs pour tous les microservices..."

services=("service-registry" "api-gateway" "order-service" "email-service" "payment-service" "product-service" "identity-service")

for service in "${services[@]}"; do
    if [ -d "$service" ]; then
        echo "📦 Construction de $service..."
        cd "$service"
        
        # Rendre mvnw exécutable
        chmod +x mvnw 2>/dev/null || true
        
        # Construire le JAR
        if [ -f "mvnw" ]; then
            ./mvnw clean package -DskipTests
        else
            mvn clean package -DskipTests
        fi
        
        if [ $? -eq 0 ]; then
            echo "✅ $service construit avec succès"
        else
            echo "❌ Erreur lors de la construction de $service"
            exit 1
        fi
        
        cd ..
    else
        echo "⚠️ Répertoire $service introuvable"
    fi
done

echo "🎉 Tous les JARs ont été construits avec succès!"

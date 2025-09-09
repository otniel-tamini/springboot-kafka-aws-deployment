# Spring Boot Kafka Microservices

## Architecture

Ce projet contient une architecture de microservices basée sur Spring Boot avec Apache Kafka pour la communication asynchrone entre services.

### Services inclus:

- **Service Registry (Eureka Server)** - Port 8761
- **API Gateway** - Port 9191
- **Order Service** - Port 8080
- **Email Service** - Port 8086
- **Payment Service** - Port 8085
- **Product Service** - Port 8084
- **Identity Service** - Port 9898

### Infrastructure:

- **Apache Kafka** - Ports 9092 (interne), 29092 (externe)
- **Zookeeper** - Port 2181
- **Redis** - Port 6379
- **MySQL (multiple instances)**:
  - Order DB - Port 3307
  - Identity DB - Port 3308
  - Payment DB - Port 3309
  - Product DB - Port 3310

## Prérequis

- Docker 20.10+
- Docker Compose 2.0+
- Make (optionnel, pour utiliser le Makefile)
- Java 17+ (pour le développement local)
- Maven 3.6+ (pour le développement local)

## Configuration

Tous les paramètres de configuration sont externalisés dans le fichier `.env`. Vous pouvez modifier ce fichier pour ajuster:

- Les ports des services
- Les versions des images Docker
- Les paramètres de base de données
- Les paramètres Kafka et Redis

## Déploiement

### Option 1: Utilisation du Makefile (Recommandée)

```bash
# Afficher l'aide
make help

# Déploiement complet (production)
make full-deploy

# Déploiement pour développement (infrastructure seulement)
make dev-setup

# Construire tous les services
make build

# Démarrer tous les services
make start

# Arrêter tous les services
make stop

# Afficher les logs
make logs

# Afficher le statut
make status

# Afficher les URLs
make urls

# Nettoyer
make clean
```

### Option 2: Utilisation du script de déploiement

```bash
# Rendre le script exécutable
chmod +x deploy.sh

# Exécuter le script interactif
./deploy.sh
```

### Option 3: Docker Compose direct

```bash
# Construire et démarrer
docker-compose up --build -d

# Arrêter
docker-compose down

# Voir les logs
docker-compose logs -f

# Voir le statut
docker-compose ps
```

## Ordre de démarrage

Les services démarrent dans l'ordre suivant grâce aux dépendances configurées:

1. **Infrastructure**: Zookeeper, Kafka, Redis, MySQL
2. **Service Discovery**: Eureka Server
3. **Services métier**: Order, Email, Payment, Product, Identity
4. **Gateway**: API Gateway

## Vérification du déploiement

### Health Checks

Tous les services exposent des endpoints de santé:

```bash
# Eureka Server
curl http://localhost:8761/actuator/health

# API Gateway
curl http://localhost:9191/actuator/health

# Order Service
curl http://localhost:8080/actuator/health

# Autres services...
```

### URLs importantes

- **Eureka Dashboard**: http://localhost:8761
- **API Gateway**: http://localhost:9191
- **Services via Gateway**: http://localhost:9191/{service-name}/**

### Test de connectivité

```bash
# Tester la connectivité automatiquement
make test-connectivity

# Ou manuellement
curl -s http://localhost:8761/actuator/health
curl -s http://localhost:9191/actuator/health
```

## Développement local

### Démarrer seulement l'infrastructure

```bash
# Avec Makefile
make start-infra

# Avec Docker Compose
docker-compose up -d zookeeper kafka redis mysql-order-service mysql-identity-service mysql-payment-service mysql-product-service
```

### Construire un service spécifique

```bash
cd service-name
./mvnw clean package -DskipTests
```

### Déboguer un service

```bash
# Voir les logs d'un service spécifique
make logs-service SERVICE=order-service

# Entrer dans le conteneur
make shell SERVICE=order-service

# Redémarrer un service
make restart-service SERVICE=order-service
```

## Variables d'environnement importantes

Les principales variables configurables dans `.env`:

```bash
# Ports des services
EUREKA_PORT=8761
API_GATEWAY_PORT=9191
ORDER_SERVICE_PORT=8080

# Base de données
MYSQL_ROOT_PASSWORD=root
DB_USERNAME=root
DB_PASSWORD=root

# Kafka
KAFKA_PORT=9092
KAFKA_HOST_PORT=29092

# Profils Spring
SPRING_PROFILES_ACTIVE=docker
```

## Résolution de problèmes

### Services qui ne démarrent pas

1. Vérifier les logs:
   ```bash
   make logs-service SERVICE=nom-du-service
   ```

2. Vérifier la connectivité réseau:
   ```bash
   docker network ls
   docker network inspect shop-network
   ```

3. Vérifier les dépendances:
   ```bash
   make status
   ```

### Problèmes de base de données

1. Vérifier que MySQL est démarré:
   ```bash
   docker-compose ps mysql-order-service
   ```

2. Se connecter à MySQL:
   ```bash
   docker-compose exec mysql-order-service mysql -uroot -proot
   ```

### Problèmes Kafka

1. Vérifier les topics:
   ```bash
   docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --list
   ```

2. Vérifier les logs Kafka:
   ```bash
   make logs-service SERVICE=kafka
   ```

## Monitoring et observabilité

### Health Checks

Tous les services incluent des health checks automatiques qui vérifient:
- La connectivité aux bases de données
- La connectivité à Kafka
- L'enregistrement auprès d'Eureka

### Logs centralisés

Les logs de tous les services sont accessibles via:
```bash
make logs
```

## Arrêt et nettoyage

```bash
# Arrêt propre
make stop

# Nettoyage complet (conteneurs + images + volumes)
make clean

# Nettoyage Docker système
docker system prune -a
```

## Architecture réseau

Tous les services communiquent via le réseau Docker `shop-network`. Les services sont accessibles:

- **Depuis l'extérieur**: via les ports mappés (localhost:port)
- **Entre conteneurs**: via les noms de service (ex: `kafka:9092`)

## Sécurité

- Les services utilisent des utilisateurs non-root dans les conteneurs
- Les bases de données utilisent des réseaux internes
- Les health checks sont configurés pour la robustesse

## Contributions

Pour contribuer au projet:

1. Fork le repository
2. Créer une branche feature
3. Tester avec `make full-deploy`
4. Soumettre une Pull Request

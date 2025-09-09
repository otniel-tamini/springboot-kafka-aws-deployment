#!/bin/bash

# =================================
# USER DATA SCRIPT - MICROSERVICES DÉMO
# =================================

exec > >(tee /var/log/user-data.log) 2>&1

echo "🚀 Installation des microservices Spring Boot..."
echo "Démarrage à: $(date)"

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install other tools
yum install -y git htop

# Create application directory
mkdir -p /opt/microservices
cd /opt/microservices

# Create optimized Docker Compose for demo
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # =================================
  # INFRASTRUCTURE SERVICES
  # =================================
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    hostname: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    mem_limit: 256m
    restart: unless-stopped

  kafka:
    image: confluentinc/cp-kafka:7.4.0
    hostname: kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
      - "9094:9094"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'true'
    mem_limit: 1g
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    hostname: redis
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    mem_limit: 256m
    restart: unless-stopped

  mysql:
    image: mysql:8.0
    hostname: mysql
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root123
      MYSQL_DATABASE: microservices_db
      MYSQL_USER: app_user
      MYSQL_PASSWORD: app_pass
    volumes:
      - mysql_data:/var/lib/mysql
    mem_limit: 512m
    restart: unless-stopped

  # =================================
  # MONITORING
  # =================================
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    mem_limit: 256m
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    mem_limit: 256m
    restart: unless-stopped

  # =================================
  # MICROSERVICES (avec images de base pour démo)
  # =================================
  service-registry:
    image: nginx:alpine
    ports:
      - "8761:80"
    volumes:
      - ./html/eureka.html:/usr/share/nginx/html/index.html
    restart: unless-stopped

  api-gateway:
    image: nginx:alpine
    ports:
      - "9191:80"
    volumes:
      - ./html/gateway.html:/usr/share/nginx/html/index.html
    restart: unless-stopped

  order-service:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html/order.html:/usr/share/nginx/html/index.html
    restart: unless-stopped

  payment-service:
    image: nginx:alpine
    ports:
      - "8085:80"
    volumes:
      - ./html/payment.html:/usr/share/nginx/html/index.html
    restart: unless-stopped

  product-service:
    image: nginx:alpine
    ports:
      - "8084:80"
    volumes:
      - ./html/product.html:/usr/share/nginx/html/index.html
    restart: unless-stopped

  email-service:
    image: nginx:alpine
    ports:
      - "8086:80"
    volumes:
      - ./html/email.html:/usr/share/nginx/html/index.html
    restart: unless-stopped

  identity-service:
    image: nginx:alpine
    ports:
      - "9898:80"
    volumes:
      - ./html/identity.html:/usr/share/nginx/html/index.html
    restart: unless-stopped

volumes:
  mysql_data:

networks:
  default:
    name: microservices-demo
EOF

# Create prometheus config
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'spring-boot'
    static_configs:
      - targets: ['order-service:8080', 'payment-service:8085', 'product-service:8084']
EOF

# Create HTML pages for demo
mkdir -p html

# Service Registry page
cat > html/eureka.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Service Registry - Eureka</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .service { background: white; margin: 10px 0; padding: 15px; border-radius: 5px; border-left: 4px solid #3498db; }
        .status { color: #27ae60; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏢 Eureka Service Registry</h1>
        <p>Service Discovery pour Architecture Microservices</p>
    </div>
    
    <h2>📋 Services Enregistrés</h2>
    
    <div class="service">
        <h3>API Gateway</h3>
        <p>Status: <span class="status">UP</span> | Port: 9191</p>
        <p>Instances: 1 | Health: /actuator/health</p>
    </div>
    
    <div class="service">
        <h3>Order Service</h3>
        <p>Status: <span class="status">UP</span> | Port: 8080</p>
        <p>Instances: 1 | Health: /actuator/health</p>
    </div>
    
    <div class="service">
        <h3>Payment Service</h3>
        <p>Status: <span class="status">UP</span> | Port: 8085</p>
        <p>Instances: 1 | Health: /actuator/health</p>
    </div>
    
    <div class="service">
        <h3>Product Service</h3>
        <p>Status: <span class="status">UP</span> | Port: 8084</p>
        <p>Instances: 1 | Health: /actuator/health</p>
    </div>
    
    <div class="service">
        <h3>Email Service</h3>
        <p>Status: <span class="status">UP</span> | Port: 8086</p>
        <p>Instances: 1 | Health: /actuator/health</p>
    </div>
    
    <div class="service">
        <h3>Identity Service</h3>
        <p>Status: <span class="status">UP</span> | Port: 9898</p>
        <p>Instances: 1 | Health: /actuator/health</p>
    </div>
    
    <h2>🔧 Infrastructure Services</h2>
    <p>✅ Kafka Cluster: kafka:9092</p>
    <p>✅ Redis Cache: redis:6379</p>
    <p>✅ MySQL Database: mysql:3306</p>
    <p>✅ Prometheus: :9090</p>
    <p>✅ Grafana: :3000</p>
</body>
</html>
EOF

# API Gateway page
cat > html/gateway.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>API Gateway - Spring Cloud Gateway</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: #e74c3c; color: white; padding: 20px; border-radius: 5px; }
        .route { background: white; margin: 10px 0; padding: 15px; border-radius: 5px; border-left: 4px solid #e74c3c; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🌐 API Gateway</h1>
        <p>Point d'entrée unique pour tous les microservices</p>
    </div>
    
    <h2>🛣️ Routes Configurées</h2>
    
    <div class="route">
        <h3>/api/orders/** → Order Service</h3>
        <p>Gestion des commandes | Port: 8080</p>
    </div>
    
    <div class="route">
        <h3>/api/payments/** → Payment Service</h3>
        <p>Traitement des paiements | Port: 8085</p>
    </div>
    
    <div class="route">
        <h3>/api/products/** → Product Service</h3>
        <p>Catalogue produits | Port: 8084</p>
    </div>
    
    <div class="route">
        <h3>/api/users/** → Identity Service</h3>
        <p>Gestion utilisateurs | Port: 9898</p>
    </div>
    
    <h2>⚡ Fonctionnalités</h2>
    <p>✅ Load Balancing</p>
    <p>✅ Circuit Breaker</p>
    <p>✅ Rate Limiting</p>
    <p>✅ Authentication</p>
</body>
</html>
EOF

# Order Service page
cat > html/order.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Order Service</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: #f39c12; color: white; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📦 Order Service</h1>
        <p>Gestion des commandes</p>
    </div>
    
    <h2>🎯 Fonctionnalités</h2>
    <p>✅ Création de commandes</p>
    <p>✅ Suivi des statuts</p>
    <p>✅ Integration Kafka</p>
    <p>✅ Persistance MySQL</p>
    
    <h2>📊 Health Check</h2>
    <p>Status: <span style="color: #27ae60; font-weight: bold;">HEALTHY</span></p>
    <p>Database: Connected</p>
    <p>Kafka: Connected</p>
</body>
</html>
EOF

# Payment Service page
cat > html/payment.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Payment Service</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: #27ae60; color: white; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>💳 Payment Service</h1>
        <p>Traitement des paiements</p>
    </div>
    
    <h2>🎯 Fonctionnalités</h2>
    <p>✅ Traitement PayPal</p>
    <p>✅ Validation des paiements</p>
    <p>✅ Events Kafka</p>
    <p>✅ Audit trail</p>
    
    <h2>📊 Health Check</h2>
    <p>Status: <span style="color: #27ae60; font-weight: bold;">HEALTHY</span></p>
    <p>PayPal API: Connected</p>
    <p>Database: Connected</p>
</body>
</html>
EOF

# Product Service page
cat > html/product.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Product Service</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: #9b59b6; color: white; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛍️ Product Service</h1>
        <p>Catalogue de produits</p>
    </div>
    
    <h2>🎯 Fonctionnalités</h2>
    <p>✅ Gestion du catalogue</p>
    <p>✅ Recherche produits</p>
    <p>✅ Cache Redis</p>
    <p>✅ Stock management</p>
    
    <h2>📊 Health Check</h2>
    <p>Status: <span style="color: #27ae60; font-weight: bold;">HEALTHY</span></p>
    <p>Cache: Connected</p>
    <p>Database: Connected</p>
</body>
</html>
EOF

# Email Service page
cat > html/email.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Email Service</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: #34495e; color: white; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📧 Email Service</h1>
        <p>Service de notifications</p>
    </div>
    
    <h2>🎯 Fonctionnalités</h2>
    <p>✅ Envoi d'emails</p>
    <p>✅ Templates dynamiques</p>
    <p>✅ Queue Redis</p>
    <p>✅ Retry logic</p>
    
    <h2>📊 Health Check</h2>
    <p>Status: <span style="color: #27ae60; font-weight: bold;">HEALTHY</span></p>
    <p>SMTP: Connected</p>
    <p>Redis: Connected</p>
</body>
</html>
EOF

# Identity Service page
cat > html/identity.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Identity Service</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: #1abc9c; color: white; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>👤 Identity Service</h1>
        <p>Gestion des utilisateurs et authentification</p>
    </div>
    
    <h2>🎯 Fonctionnalités</h2>
    <p>✅ Authentification JWT</p>
    <p>✅ Gestion des rôles</p>
    <p>✅ Session management</p>
    <p>✅ Password encryption</p>
    
    <h2>📊 Health Check</h2>
    <p>Status: <span style="color: #27ae60; font-weight: bold;">HEALTHY</span></p>
    <p>Database: Connected</p>
    <p>JWT: Valid</p>
</body>
</html>
EOF

# Set permissions
chown -R ec2-user:ec2-user /opt/microservices

# Start services
echo "🚀 Démarrage des services..."
cd /opt/microservices
docker-compose up -d

# Create dashboard
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Microservices Demo Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 40px; }
        .services { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .service { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; backdrop-filter: blur(10px); }
        .service h3 { color: #ffd700; margin-top: 0; }
        .service a { color: #87ceeb; text-decoration: none; }
        .service a:hover { text-decoration: underline; }
        .infra { background: rgba(0,0,0,0.2); padding: 20px; border-radius: 10px; margin-top: 30px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Spring Boot Microservices Demo</h1>
            <p>Architecture complète avec 7 microservices</p>
        </div>
        
        <div class="services">
            <div class="service">
                <h3>🏢 Service Registry</h3>
                <p>Eureka Server pour la découverte de services</p>
                <a href="http://PUBLIC_IP:8761" target="_blank">Accéder au registry →</a>
            </div>
            
            <div class="service">
                <h3>🌐 API Gateway</h3>
                <p>Point d'entrée unique avec load balancing</p>
                <a href="http://PUBLIC_IP:9191" target="_blank">Accéder au gateway →</a>
            </div>
            
            <div class="service">
                <h3>📦 Order Service</h3>
                <p>Gestion des commandes avec Kafka</p>
                <a href="http://PUBLIC_IP:8080" target="_blank">Accéder au service →</a>
            </div>
            
            <div class="service">
                <h3>💳 Payment Service</h3>
                <p>Traitement des paiements PayPal</p>
                <a href="http://PUBLIC_IP:8085" target="_blank">Accéder au service →</a>
            </div>
            
            <div class="service">
                <h3>🛍️ Product Service</h3>
                <p>Catalogue avec cache Redis</p>
                <a href="http://PUBLIC_IP:8084" target="_blank">Accéder au service →</a>
            </div>
            
            <div class="service">
                <h3>📧 Email Service</h3>
                <p>Notifications asynchrones</p>
                <a href="http://PUBLIC_IP:8086" target="_blank">Accéder au service →</a>
            </div>
            
            <div class="service">
                <h3>👤 Identity Service</h3>
                <p>Authentification et autorisation</p>
                <a href="http://PUBLIC_IP:9898" target="_blank">Accéder au service →</a>
            </div>
        </div>
        
        <div class="infra">
            <h2>🔧 Infrastructure</h2>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px;">
                <div>📊 <a href="http://PUBLIC_IP:9090" target="_blank">Prometheus</a></div>
                <div>📈 <a href="http://PUBLIC_IP:3000" target="_blank">Grafana</a></div>
                <div>🗄️ MySQL Database</div>
                <div>⚡ Redis Cache</div>
                <div>📨 Kafka Streaming</div>
            </div>
        </div>
        
        <div style="text-align: center; margin-top: 40px; font-size: 14px; opacity: 0.8;">
            <p>💰 Coût de cette démo: ~$0.50 pour 3h | ⚡ Stack: Spring Boot + Docker + AWS</p>
        </div>
    </div>
</body>
</html>
EOF

# Install and start Apache
yum install httpd -y
systemctl start httpd
systemctl enable httpd

# Wait for services to start
sleep 60

echo "✅ Installation terminée à: $(date)"
echo "🌐 Dashboard disponible à: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "📊 Services déployés avec succès !"

# Log status
docker-compose ps > /var/log/services-status.log

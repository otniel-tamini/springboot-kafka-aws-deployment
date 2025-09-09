#!/bin/bash

# =================================
# AMAZON LINUX 2 SETUP SCRIPT
# =================================

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
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Git
yum install git -y

# Create application directory
mkdir -p /opt/springboot-app
cd /opt/springboot-app

# Create Docker Compose file for the microservices
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # =================================
  # INFRASTRUCTURE SERVICES
  # =================================
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    hostname: zookeeper
    container_name: zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    mem_limit: 512m

  kafka:
    image: confluentinc/cp-kafka:7.4.0
    hostname: kafka
    container_name: kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_CONFLUENT_SCHEMA_REGISTRY_URL: http://schema-registry:8081
    mem_limit: 1g

  redis:
    image: redis:7-alpine
    hostname: redis
    container_name: redis
    ports:
      - "6379:6379"
    mem_limit: 256m

  # =================================
  # MICROSERVICES
  # =================================
  service-registry:
    image: ${service_registry_image:-openjdk:11-jre-slim}
    container_name: service-registry
    ports:
      - "8761:8761"
    environment:
      - SPRING_PROFILES_ACTIVE=docker
    mem_limit: 512m
    restart: unless-stopped

  api-gateway:
    image: ${api_gateway_image:-openjdk:11-jre-slim}
    container_name: api-gateway
    ports:
      - "9191:9191"
    depends_on:
      - service-registry
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE=http://service-registry:8761/eureka
    mem_limit: 512m
    restart: unless-stopped

  order-service:
    image: ${order_service_image:-openjdk:11-jre-slim}
    container_name: order-service
    ports:
      - "8080:8080"
    depends_on:
      - service-registry
      - kafka
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_DATASOURCE_URL=jdbc:mysql://${db_host}:3306/main_db
      - SPRING_DATASOURCE_USERNAME=root
      - SPRING_DATASOURCE_PASSWORD=${db_password}
      - SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:29092
      - EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE=http://service-registry:8761/eureka
    mem_limit: 768m
    restart: unless-stopped

  payment-service:
    image: ${payment_service_image:-openjdk:11-jre-slim}
    container_name: payment-service
    ports:
      - "8085:8085"
    depends_on:
      - service-registry
      - kafka
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_DATASOURCE_URL=jdbc:mysql://${db_host}:3306/main_db
      - SPRING_DATASOURCE_USERNAME=root
      - SPRING_DATASOURCE_PASSWORD=${db_password}
      - SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:29092
      - EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE=http://service-registry:8761/eureka
    mem_limit: 768m
    restart: unless-stopped

  product-service:
    image: ${product_service_image:-openjdk:11-jre-slim}
    container_name: product-service
    ports:
      - "8084:8084"
    depends_on:
      - service-registry
      - kafka
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_DATASOURCE_URL=jdbc:mysql://${db_host}:3306/main_db
      - SPRING_DATASOURCE_USERNAME=root
      - SPRING_DATASOURCE_PASSWORD=${db_password}
      - SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:29092
      - EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE=http://service-registry:8761/eureka
    mem_limit: 768m
    restart: unless-stopped

  email-service:
    image: ${email_service_image:-openjdk:11-jre-slim}
    container_name: email-service
    ports:
      - "8086:8086"
    depends_on:
      - service-registry
      - kafka
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:29092
      - EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE=http://service-registry:8761/eureka
      - SPRING_DATA_REDIS_HOST=redis
      - SPRING_DATA_REDIS_PORT=6379
    mem_limit: 512m
    restart: unless-stopped

  identity-service:
    image: ${identity_service_image:-openjdk:11-jre-slim}
    container_name: identity-service
    ports:
      - "9898:9898"
    depends_on:
      - service-registry
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_DATASOURCE_URL=jdbc:mysql://${db_host}:3306/main_db
      - SPRING_DATASOURCE_USERNAME=root
      - SPRING_DATASOURCE_PASSWORD=${db_password}
      - EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE=http://service-registry:8761/eureka
    mem_limit: 768m
    restart: unless-stopped

networks:
  default:
    name: microservices-network
EOF

# Set proper permissions
chown -R ec2-user:ec2-user /opt/springboot-app

# Create systemd service for auto-start
cat > /etc/systemd/system/microservices.service << 'EOF'
[Unit]
Description=Spring Boot Microservices
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/opt/springboot-app
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ec2-user

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable microservices.service

# Create management scripts
cat > /opt/springboot-app/start.sh << 'EOF'
#!/bin/bash
cd /opt/springboot-app
docker-compose up -d
echo "Microservices started successfully!"
echo "Services available at:"
echo "- Service Registry: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8761"
echo "- API Gateway: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9191"
EOF

cat > /opt/springboot-app/stop.sh << 'EOF'
#!/bin/bash
cd /opt/springboot-app
docker-compose down
echo "Microservices stopped!"
EOF

cat > /opt/springboot-app/status.sh << 'EOF'
#!/bin/bash
cd /opt/springboot-app
docker-compose ps
EOF

# Make scripts executable
chmod +x /opt/springboot-app/*.sh

# Create a simple web dashboard
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Spring Boot Microservices - Dev Environment</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .service { 
            background: #f5f5f5; 
            padding: 15px; 
            margin: 10px 0; 
            border-radius: 5px; 
        }
        .service a { 
            color: #007bff; 
            text-decoration: none; 
            font-weight: bold; 
        }
    </style>
</head>
<body>
    <h1>🚀 Spring Boot Microservices - Development Environment</h1>
    <p>Welcome to your microservices development environment on AWS Free Tier!</p>
    
    <h2>📊 Available Services</h2>
    <div class="service">
        <strong>Service Registry (Eureka)</strong><br>
        <a href="http://PUBLIC_IP:8761" target="_blank">http://PUBLIC_IP:8761</a>
    </div>
    
    <div class="service">
        <strong>API Gateway</strong><br>
        <a href="http://PUBLIC_IP:9191" target="_blank">http://PUBLIC_IP:9191</a>
    </div>
    
    <div class="service">
        <strong>Order Service</strong><br>
        <a href="http://PUBLIC_IP:8080/actuator/health" target="_blank">http://PUBLIC_IP:8080</a>
    </div>
    
    <div class="service">
        <strong>Payment Service</strong><br>
        <a href="http://PUBLIC_IP:8085/actuator/health" target="_blank">http://PUBLIC_IP:8085</a>
    </div>
    
    <div class="service">
        <strong>Product Service</strong><br>
        <a href="http://PUBLIC_IP:8084/actuator/health" target="_blank">http://PUBLIC_IP:8084</a>
    </div>
    
    <div class="service">
        <strong>Email Service</strong><br>
        <a href="http://PUBLIC_IP:8086/actuator/health" target="_blank">http://PUBLIC_IP:8086</a>
    </div>
    
    <div class="service">
        <strong>Identity Service</strong><br>
        <a href="http://PUBLIC_IP:9898/actuator/health" target="_blank">http://PUBLIC_IP:9898</a>
    </div>
    
    <h2>🛠️ Management Commands</h2>
    <pre>
# SSH to server
ssh -i your-key.pem ec2-user@PUBLIC_IP

# Check services status
sudo docker-compose ps

# View logs
sudo docker-compose logs -f [service-name]

# Restart services
sudo docker-compose restart

# Stop all services
sudo docker-compose down

# Start all services
sudo docker-compose up -d
    </pre>
    
    <p><strong>Note:</strong> Replace PUBLIC_IP with your actual EC2 public IP address.</p>
</body>
</html>
EOF

# Install and start simple HTTP server for dashboard
yum install httpd -y
systemctl start httpd
systemctl enable httpd

echo "Setup completed! Microservices will start automatically."

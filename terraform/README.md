# SpringBoot Kafka Microservices - Infrastructure as Code

Cette configuration Terraform déploie l'architecture complète des microservices Spring Boot avec Kafka sur AWS EKS.

## 🏗️ Architecture

L'infrastructure déployée comprend :

### **Services AWS**
- **EKS (Elastic Kubernetes Service)** : Cluster Kubernetes managé
- **VPC** : Réseau privé virtuel avec subnets publics et privés
- **RDS** : Bases de données MySQL pour chaque microservice
- **ElastiCache** : Cache Redis distribué
- **MSK** : Kafka managé (Managed Streaming for Kafka)
- **CloudWatch** : Monitoring et logs

### **Microservices**
- **Service Registry** (Eureka Server) : Découverte de services
- **API Gateway** : Point d'entrée unique pour les APIs
- **Order Service** : Gestion des commandes
- **Payment Service** : Traitement des paiements
- **Product Service** : Gestion des produits
- **Email Service** : Envoi d'emails
- **Identity Service** : Authentification et autorisation

### **Infrastructure de Monitoring**
- **Prometheus** : Collecte de métriques
- **Grafana** : Visualisation des métriques
- **Loki** : Agrégation des logs

## 📋 Prérequis

### Outils requis
```bash
# Vérifier les outils installés
make check-tools
```

- **Terraform** >= 1.0
- **AWS CLI** configuré avec vos credentials
- **kubectl** pour la gestion Kubernetes
- **Docker** pour construire les images
- **Helm** (optionnel, pour déploiements avancés)

### Configuration AWS
```bash
# Configurer AWS CLI
aws configure

# Vérifier la configuration
aws sts get-caller-identity
```

## 🚀 Déploiement Rapide

### 1. **Environnement de Développement**
```bash
# Déployer l'environnement de développement complet
make dev-up

# Configurer kubectl
make kubeconfig ENV=dev

# Vérifier le statut
make k8s-status
```

### 2. **Construction et Déploiement des Images**
```bash
# Construire les images Docker
make build

# Pousser vers votre registry (optionnel)
make push DOCKER_REGISTRY=your-registry.com
```

### 3. **Accès aux Services**
```bash
# Démarrer les dashboards de monitoring
make monitoring-dashboard

# URLs d'accès :
# - Grafana: http://localhost:3000 (admin/admin123)
# - Prometheus: http://localhost:9090
# - Eureka: http://localhost:8761
```

## 📁 Structure du Projet

```
terraform/
├── main.tf                    # Configuration principale
├── variables.tf               # Variables globales
├── outputs.tf                 # Sorties Terraform
├── Makefile                   # Commandes automatisées
├── environments/              # Configurations par environnement
│   ├── dev/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       └── terraform.tfvars
├── modules/                   # Modules Terraform réutilisables
│   ├── vpc/                   # Module VPC
│   ├── eks/                   # Module EKS
│   ├── rds/                   # Module bases de données
│   ├── elasticache/           # Module Redis
│   ├── msk/                   # Module Kafka
│   └── monitoring/            # Module monitoring
└── kubernetes/                # Configurations Kubernetes
    └── microservices.tf       # Déploiements des microservices
```

## ⚙️ Configuration des Environnements

### Environnement de Développement (`dev`)
- **Instances** : t3.medium (2 nodes)
- **Bases de données** : db.t3.micro
- **Redis** : cache.t3.micro
- **Kafka** : kafka.t3.small (3 brokers)

### Environnement de Production (`prod`)
- **Instances** : t3.large (5 nodes + spot instances)
- **Bases de données** : db.t3.small avec Multi-AZ
- **Redis** : cache.t3.small avec réplication
- **Kafka** : kafka.m5.large (6 brokers)

## 🔧 Commandes Terraform

### Commandes de Base
```bash
# Initialiser Terraform
make init ENV=dev

# Planifier les changements
make plan ENV=dev

# Appliquer les changements
make apply ENV=dev

# Détruire l'infrastructure
make destroy ENV=dev
```

### Gestion des États
```bash
# Rafraîchir l'état
make refresh ENV=dev

# Voir les sorties
make output ENV=dev

# Valider la configuration
make validate
```

## 🐳 Gestion Docker

### Construction des Images
```bash
# Construire toutes les images
make build

# Construire une image spécifique
docker-compose -f docker-compose-build.yml build order-service
```

### Registry Docker
```bash
# Configurer le registry
export DOCKER_REGISTRY=your-registry.com

# Pousser toutes les images
make push

# Pousser une image spécifique
docker push $DOCKER_REGISTRY/order-service:latest
```

## ☸️ Gestion Kubernetes

### Configuration kubectl
```bash
# Configurer kubectl automatiquement
make kubeconfig ENV=dev

# Configuration manuelle
aws eks update-kubeconfig --region us-west-2 --name springboot-kafka-microservices-dev-cluster
```

### Déploiement des Applications
```bash
# Déployer tous les microservices
make deploy-apps ENV=dev

# Vérifier le statut
kubectl get pods
kubectl get services
```

### Debugging
```bash
# Voir les logs d'un service
make logs SVC=order-service

# Logs en temps réel
kubectl logs -f deployment/order-service

# Décrire un pod
kubectl describe pod <pod-name>
```

## 📊 Monitoring et Observabilité

### Accès aux Dashboards
```bash
# Démarrer tous les port-forwards
make monitoring-dashboard

# Accès individuel
kubectl port-forward -n monitoring svc/prometheus-operator-grafana 3000:80
kubectl port-forward -n monitoring svc/prometheus-operator-kube-p-prometheus 9090:9090
kubectl port-forward svc/eureka-server 8761:8761
```

### Métriques Disponibles
- **Applications** : Métriques Spring Boot via Micrometer
- **Infrastructure** : Métriques Kubernetes et AWS
- **Base de données** : Métriques RDS et ElastiCache
- **Kafka** : Métriques MSK

### Dashboards Grafana
- **Spring Boot Applications** : Métriques JVM, HTTP, DB
- **Kubernetes Cluster** : Nodes, Pods, Resources
- **Infrastructure** : AWS Resources, Costs

## 🔒 Sécurité

### Secrets Management
```bash
# Les mots de passe sont stockés dans Kubernetes Secrets
kubectl get secrets -n default

# Voir un secret
kubectl get secret db-passwords -o yaml
```

### Accès Réseau
- **VPC** : Isolation réseau complète
- **Security Groups** : Règles de firewall restrictives
- **Private Subnets** : Bases de données et Kafka en privé
- **NAT Gateways** : Accès internet sortant sécurisé

### Chiffrement
- **RDS** : Chiffrement au repos activé
- **ElastiCache** : Chiffrement au repos activé
- **MSK** : Chiffrement in-transit et at-rest
- **EKS** : Secrets chiffrés avec AWS KMS

## 💰 Estimation des Coûts

```bash
# Estimer les coûts (nécessite infracost)
make cost-estimate ENV=dev

# Installation d'infracost
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
```

### Coûts Approximatifs (us-west-2)
- **Dev** : ~$150-200/mois
- **Prod** : ~$800-1200/mois

## 🚨 Dépannage

### Problèmes Courants

1. **Terraform init échoue**
   ```bash
   # Nettoyer et réinitialiser
   make clean
   make init ENV=dev
   ```

2. **Pods en erreur CrashLoopBackOff**
   ```bash
   # Vérifier les logs
   kubectl logs <pod-name>
   # Vérifier la configuration
   kubectl describe pod <pod-name>
   ```

3. **Services inaccessibles**
   ```bash
   # Vérifier les services
   kubectl get svc
   # Vérifier les endpoints
   kubectl get endpoints
   ```

4. **Problèmes de connectivité base de données**
   ```bash
   # Tester la connectivité
   kubectl exec -it <pod-name> -- mysql -h <rds-endpoint> -u root -p
   ```

### Logs Utiles
```bash
# Logs Terraform
terraform apply 2>&1 | tee terraform.log

# Logs Kubernetes
kubectl get events --sort-by=.metadata.creationTimestamp

# Logs des applications
kubectl logs -f deployment/<service-name> --tail=100
```

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to AWS
        run: |
          make init ENV=dev
          make plan ENV=dev
          make apply ENV=dev
```

### GitLab CI Example
```yaml
deploy:
  stage: deploy
  script:
    - make init ENV=dev
    - make apply ENV=dev
  only:
    - main
```

## 🆘 Support

### Ressources Utiles
- [Documentation Terraform AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Documentation EKS](https://docs.aws.amazon.com/eks/)
- [Documentation Spring Boot](https://spring.io/projects/spring-boot)
- [Documentation Kafka](https://kafka.apache.org/documentation/)

### Commandes d'Aide
```bash
# Aide générale
make help

# Exemples d'utilisation
make examples

# Vérifier les outils
make check-tools
```

## 📝 Notes Importantes

1. **State Management** : Configurez un backend S3 pour le state Terraform en production
2. **Secrets** : Changez tous les mots de passe par défaut en production
3. **Monitoring** : Configurez des alertes Grafana pour la production
4. **Backups** : Activez les snapshots automatiques pour RDS
5. **Scaling** : Configurez l'autoscaling pour les node groups EKS

## 🤝 Contribution

1. Fork le projet
2. Créez une branche feature (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

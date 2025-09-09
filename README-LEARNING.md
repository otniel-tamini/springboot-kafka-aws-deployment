# 🚀 SpringBoot Kafka AWS Deployment

> **Projet d'apprentissage** : Déploiement de microservices sur AWS avec Terraform, Kubernetes et CI/CD

## 🎯 Objectif d'apprentissage

Ce repository est votre environnement d'apprentissage pour maîtriser le déploiement d'applications microservices sur AWS. Basé sur une architecture e-commerce complète, vous apprendrez :

- ☁️ **AWS Infrastructure** avec Terraform (EKS, VPC, RDS, S3, CloudFront)
- 🐳 **Containerisation** et orchestration Kubernetes
- 🔄 **CI/CD automatisé** avec GitHub Actions
- 📊 **Monitoring** et observabilité
- 🛡️ **Sécurité** et best practices AWS

## 📖 Guide d'apprentissage

📚 **[Consultez le guide d'apprentissage détaillé](./LEARNING-GUIDE.md)** pour un parcours structuré de 4 semaines avec exercices pratiques.

## 🏗️ Architecture microservices

Cette plateforme e-commerce comprend 7 microservices Spring Boot :

### Services métier
- **🛍️ Product Service** : Gestion catalogue produits
- **📦 Order Service** : Gestion des commandes  
- **💳 Payment Service** : Traitement des paiements
- **👤 Identity Service** : Authentification et autorisation
- **📧 Email Service** : Notifications par email

### Services infrastructure
- **🌐 API Gateway** : Point d'entrée unique avec Spring Cloud Gateway
- **📋 Service Registry** : Découverte de services avec Eureka

### Services transverses
- **🔄 Apache Kafka** : Messaging et événements
- **🗄️ MySQL** : Base de données relationnelle
- **⚡ Redis** : Cache et sessions
- **⚛️ React Frontend** : Interface utilisateur moderne

## 🚀 Quick Start

### 1. Prérequis
```bash
# Installer les outils requis
- AWS CLI configuré avec vos credentials
- kubectl pour Kubernetes
- Terraform >= 1.5
- Docker et Docker Compose
- Node.js 18+ et npm
- Java 17+ et Maven
```

### 2. Configuration initiale
```bash
# Cloner votre repository
git clone git@github.com:otniel-tamini/springboot-kafka-aws-deployment.git
cd springboot-kafka-aws-deployment

# Configurer les pipelines CI/CD
cd .github
./setup-ci-cd.sh
```

### 3. Déploiement infrastructure
```bash
# Déployer sur AWS avec Terraform
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec vos paramètres

terraform init
terraform plan
terraform apply
```

### 4. Déploiement applications
```bash
# Les pipelines CI/CD se déclenchent automatiquement sur push
git add .
git commit -m "Initial deployment"
git push origin main

# Ou déploiement manuel avec Ansible
cd playbooks
ansible-playbook deploy-microservices.yml -e environment=dev
```

## 📊 Progression d'apprentissage

### Phase 1 : Infrastructure (Semaine 1)
- [x] 🏗️ VPC et réseaux AWS
- [x] ⚙️ Cluster EKS Kubernetes  
- [x] 🗄️ RDS MySQL managé
- [x] ⚡ ElastiCache Redis
- [x] 🔒 Security Groups et IAM

### Phase 2 : Applications (Semaine 2)  
- [x] 🐳 Containerisation Docker
- [x] ☸️ Déploiement Kubernetes
- [x] 🔄 Kafka pour messaging
- [x] 🌐 Load balancing ALB/NLB
- [x] 📊 Health checks et monitoring

### Phase 3 : Frontend et CI/CD (Semaine 3)
- [x] ⚛️ React app sur S3 + CloudFront
- [x] 🔄 Pipelines GitHub Actions
- [x] 📦 ECR pour images Docker
- [x] 🚀 Déploiements automatisés
- [x] 🔍 Tests et security scanning

### Phase 4 : Production (Semaine 4)
- [ ] 📈 Monitoring Prometheus/Grafana
- [ ] 📋 Logging ELK Stack
- [ ] 🚨 Alerting et notifications
- [ ] 💾 Backup et disaster recovery

## 🛠️ Technologies apprises

### ☁️ AWS Services
- **EKS** : Kubernetes managé
- **ECR** : Registry Docker privé  
- **S3** : Stockage statique
- **CloudFront** : CDN global
- **RDS** : Base de données managée
- **ElastiCache** : Cache Redis managé
- **VPC** : Réseau privé virtuel
- **ALB/NLB** : Load balancers

### 🔧 Outils DevOps
- **Terraform** : Infrastructure as Code
- **Ansible** : Configuration management
- **GitHub Actions** : CI/CD pipelines
- **Docker** : Containerisation
- **Kubernetes** : Orchestration
- **Helm** : Package manager K8s

### 💻 Stack technique
- **Spring Boot** : Framework Java microservices
- **Apache Kafka** : Event streaming
- **React** : Frontend moderne
- **MySQL** : Base de données relationnelle  
- **Redis** : Cache in-memory
- **Nginx** : Reverse proxy

## 📈 Compétences développées

À la fin de ce projet, vous maîtriserez :

### 🏗️ Architecture Cloud
- Conception d'infrastructure AWS scalable
- Sécurisation des réseaux et accès
- Optimisation des coûts cloud
- Haute disponibilité et disaster recovery

### 🔄 DevOps et CI/CD  
- Automatisation des déploiements
- Pipelines de build et test
- Monitoring et observabilité
- Gestion des secrets et configurations

### ☸️ Kubernetes et containers
- Orchestration de microservices
- Service mesh et networking
- Scaling automatique
- Debugging et troubleshooting

## 🎯 Exercices pratiques

Le guide d'apprentissage inclut des exercices concrets :

1. **🏃‍♂️ Infrastructure Setup** : Déployer VPC et EKS
2. **🏃‍♂️ Application Deployment** : Containers et K8s
3. **🏃‍♂️ CI/CD Implementation** : Automatiser les pipelines  
4. **🏃‍♂️ Production Readiness** : Monitoring et alerting

## 📚 Ressources d'apprentissage

### Documentation
- [Guide d'apprentissage complet](./LEARNING-GUIDE.md)
- [Configuration CI/CD](./.github/README.md)
- [Documentation pipelines](./.github/PIPELINES.md)

### Certifications ciblées
- AWS Certified Solutions Architect
- AWS Certified DevOps Engineer  
- Certified Kubernetes Administrator (CKA)
- Terraform Associate

## 🛟 Support et troubleshooting

### 🔧 Problèmes courants
```bash
# Vérifier le cluster EKS
kubectl get nodes
kubectl get pods --all-namespaces

# Vérifier les pipelines
# GitHub Actions > Actions tab
# Consulter les logs détaillés

# Vérifier l'infrastructure  
cd terraform/environments/dev
terraform plan
```

### 📞 Aide
- 📝 Créer une issue GitHub pour les questions
- 📖 Consulter la documentation dans `/docs`
- 🔍 Logs disponibles dans AWS CloudWatch
- 📊 Métriques dans AWS Console

## 🎉 Contribution

Ce projet est destiné à l'apprentissage. N'hésitez pas à :
- 🔧 Expérimenter avec les configurations
- 📝 Documenter vos découvertes  
- 🚀 Ajouter de nouvelles fonctionnalités
- 🐛 Signaler et corriger les bugs

---

**🚀 Bon apprentissage du déploiement AWS !**

> 💡 **Conseil** : Suivez le guide d'apprentissage étape par étape. L'infrastructure AWS peut sembler complexe, mais devient intuitive avec la pratique régulière.

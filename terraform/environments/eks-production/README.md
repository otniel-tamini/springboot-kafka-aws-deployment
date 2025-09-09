# 🚀 Configuration EKS Production - Déploiement Complet

## 📋 Vue d'ensemble

Cette configuration Terraform déploie une **architecture EKS production-ready** complète avec :

### 🏗️ **Infrastructure**
- **Cluster EKS** avec 3 node groups spécialisés
- **6 nœuds minimum** (3 microservices + 2 infrastructure + 1 monitoring)
- **Multi-AZ** pour haute disponibilité
- **Auto-scaling** automatique
- **Load balancing** avec AWS ALB

### 💾 **Services de données**
- **4 bases MySQL RDS** dédiées (Multi-AZ, chiffrées)
- **Redis ElastiCache** (cluster Multi-AZ)
- **Apache Kafka MSK** (3 brokers)

### 🔍 **Monitoring & Observabilité**
- **Prometheus** pour les métriques
- **Grafana** pour les dashboards
- **CloudWatch** intégré
- **Health checks** automatiques

### 🛡️ **Sécurité**
- **Network policies** Kubernetes
- **Security groups** AWS dédiés
- **IAM roles** avec principe du moindre privilège
- **Chiffrement** en transit et au repos

## 📊 **Architecture des Node Groups**

```
📦 Node Group: microservices (3 nœuds t3.large)
├── 🌐 API Gateway (3 replicas)
├── 📦 Order Service (3 replicas)
├── 💳 Payment Service (3 replicas)
├── 📦 Product Service (3 replicas)
├── 📧 Email Service (2 replicas)
└── 👤 Identity Service (3 replicas)

🔧 Node Group: infrastructure (2 nœuds t3.medium)
├── 📋 Service Registry (2 replicas)
├── ⚖️  AWS Load Balancer Controller
└── 🔄 Cluster Autoscaler

📊 Node Group: monitoring (1 nœud t3.medium SPOT)
├── 📈 Prometheus
├── 📊 Grafana
└── 📋 Monitoring agents
```

## 💰 **Estimation des coûts**

| Composant | Configuration | Coût mensuel (USD) |
|-----------|---------------|-------------------|
| **EKS Cluster** | Control plane | $72 |
| **Node Groups** | | |
| - Microservices | 3x t3.large | $97 |
| - Infrastructure | 2x t3.medium | $49 |
| - Monitoring | 1x t3.medium (SPOT) | $24 |
| **RDS MySQL** | 4x db.t3.medium Multi-AZ | $249 |
| **ElastiCache Redis** | 2x cache.t3.medium | $79 |
| **MSK Kafka** | 3x kafka.t3.small | $43 |
| **Réseau & Stockage** | NAT, EBS, transferts | $40 |
| **TOTAL ESTIMÉ** | | **~$750/mois** |

## 🚀 **Déploiement**

### 1. **Prérequis**
```bash
# Installer les outils nécessaires
aws configure  # Configurer AWS CLI
kubectl version  # Vérifier kubectl
terraform version  # Vérifier Terraform
helm version  # Vérifier Helm
```

### 2. **Lancer le déploiement**
```bash
cd /home/otniel/springboot-kafka-microservices/terraform/environments/eks-production
./deploy.sh
```

### 3. **Vérification**
```bash
# Vérifier le cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Vérifier les services
kubectl get svc --all-namespaces
kubectl get ingress --all-namespaces
```

## 🔧 **Configuration post-déploiement**

### 📊 **Accès Grafana**
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# Ouvrir http://localhost:3000
# User: admin, Password: voir output Terraform
```

### 📈 **Accès Prometheus**
```bash
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Ouvrir http://localhost:9090
```

### 🌐 **Accès API Gateway**
```bash
# Via Load Balancer (production)
kubectl get ingress api-gateway-ingress -n microservices

# Via port-forward (développement)
kubectl port-forward -n microservices svc/api-gateway 8080:8080
```

## 📝 **Microservices déployés**

| Service | Port | Replicas | Description |
|---------|------|----------|-------------|
| **Service Registry** | 8761 | 2 | Eureka Discovery Server |
| **API Gateway** | 8080 | 3 | Point d'entrée unique |
| **Order Service** | 8081 | 3 | Gestion des commandes |
| **Payment Service** | 8082 | 3 | Traitement des paiements |
| **Product Service** | 8083 | 3 | Catalogue produits |
| **Email Service** | 8084 | 2 | Notifications email |
| **Identity Service** | 8085 | 3 | Authentification |

## 🔍 **Monitoring & Debugging**

### **Logs des pods**
```bash
kubectl logs -f deployment/api-gateway -n microservices
kubectl logs -f deployment/order-service -n microservices
```

### **Métriques des ressources**
```bash
kubectl top nodes
kubectl top pods --all-namespaces
```

### **Statut des deployments**
```bash
kubectl get deployments --all-namespaces
kubectl describe deployment api-gateway -n microservices
```

## 🛡️ **Sécurité**

### **Network Policies**
- Isolation des namespaces
- Communication contrôlée entre services
- Accès externe restreint

### **IAM & RBAC**
- Rôles dédiés par composant
- Permissions minimales
- Intégration AWS IAM avec Kubernetes RBAC

### **Chiffrement**
- TLS pour toutes les communications
- Chiffrement des volumes EBS
- Chiffrement des bases de données

## 🔄 **Haute disponibilité**

### **Multi-AZ**
- Nœuds répartis sur 3 zones de disponibilité
- Bases de données Multi-AZ
- Load balancers multi-zones

### **Auto-scaling**
- Cluster Autoscaler pour les nœuds
- HPA pour les pods
- Métriques personnalisées

## 🧹 **Destruction de l'infrastructure**

```bash
cd /home/otniel/springboot-kafka-microservices/terraform/environments/eks-production
./destroy.sh
```

⚠️ **ATTENTION**: Cette action supprime TOUTE l'infrastructure et les données de manière irréversible.

## 📞 **Support & Maintenance**

### **Commandes utiles**
```bash
# État général du cluster
kubectl cluster-info

# Événements récents
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Ressources consommées
kubectl describe nodes

# Redémarrer un service
kubectl rollout restart deployment/api-gateway -n microservices
```

### **Mise à jour**
```bash
# Mise à jour des images
kubectl set image deployment/api-gateway api-gateway=haphong463/api-gateway:v2.0 -n microservices

# Mise à jour Terraform
terraform plan
terraform apply
```

---

## 🎯 **Cette configuration est PRODUCTION-READY avec :**

✅ **Haute disponibilité** (Multi-AZ, réplication)  
✅ **Scalabilité automatique** (nœuds et pods)  
✅ **Monitoring complet** (Prometheus + Grafana)  
✅ **Sécurité renforcée** (chiffrement, IAM, network policies)  
✅ **Performance optimisée** (node groups spécialisés)  
✅ **Coûts contrôlés** (SPOT pour monitoring, tailles optimisées)  

🚀 **Prêt pour un déploiement professionnel !**

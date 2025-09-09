# 🎯 Configuration DEV - Budget $200/mois

Cette configuration vous offre un environnement de développement complet sur AWS pour environ **$200/mois**, optimisé pour le développement tout en restant économique.

## 💰 **Estimation des coûts : ~$212/mois**

### 📊 **Répartition des coûts :**

| Service | Configuration | Coût mensuel | Optimisation |
|---------|---------------|--------------|--------------|
| **EKS Control Plane** | 1 cluster | $73.00 | ❌ Incompressible |
| **EC2 Nodes** | 2x t3.small SPOT | $15.00 | ✅ SPOT (-70%) |
| **RDS MySQL** | 1x db.t3.micro | $16.00 | ✅ Partagée |
| **ElastiCache Redis** | 1x cache.t3.micro | $17.00 | ✅ Minimale |
| **MSK Kafka** | 2x kafka.t3.small | $60.00 | ✅ 2 brokers |
| **EBS Storage** | 40GB + 100GB | $8.00 | ✅ Optimisé |
| **Load Balancer** | 1x ALB | $18.00 | ✅ Partagé |
| **Data Transfer** | Inter-AZ + Internet | $5.00 | ✅ Minimal |
| **TOTAL** | | **$212.00** | **85% d'économie vs prod** |

## 🏗️ **Architecture optimisée :**

```
Internet
    ↓
[ALB] → [EKS Cluster]
         ├── 2x t3.small SPOT nodes
         ├── Service Registry (1 replica)
         ├── API Gateway (1 replica)
         ├── Order Service (1 replica)
         ├── Payment Service (1 replica)
         ├── Product Service (1 replica)
         ├── Email Service (1 replica)
         └── Identity Service (1 replica)
         ↓
[RDS MySQL Shared] ← Base unique partagée
[ElastiCache Redis] ← Cache partagé
[MSK Kafka] ← 2 brokers
```

## ✅ **Optimisations appliquées :**

### **Économies majeures :**
- ✅ **SPOT instances** : -70% sur les coûts EC2
- ✅ **Base unique partagée** : au lieu de 4 bases séparées
- ✅ **2 AZ seulement** : au lieu de 3
- ✅ **Pas de NAT Gateway** : -$45/mois
- ✅ **1 réplique par service** : au lieu de 2-3
- ✅ **Instances minimales** : t3.small au lieu de t3.medium
- ✅ **Stockage optimisé** : Tailles minimales

### **Monitoring basique :**
- ✅ Prometheus + Grafana
- ❌ Pas de logging centralisé (ELK)
- ❌ Pas de multi-AZ
- ❌ Pas de monitoring détaillé CloudWatch

## 🚀 **Déploiement :**

```bash
cd terraform/environments/dev-budget

# Initialiser
terraform init

# Vérifier le plan
terraform plan

# Déployer
terraform apply

# Connecter kubectl
aws eks update-kubeconfig --region us-west-2 --name springboot-kafka-dev
```

## 📈 **Gestion des coûts :**

### **Surveillance :**
```bash
# Vérifier l'utilisation
kubectl top nodes
kubectl top pods -A

# Surveiller les coûts AWS
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

### **Économies supplémentaires :**
- 🕐 **Arrêt nocturne** : Arrêter l'environnement la nuit/weekend (-40%)
- 📊 **Alertes budget** : Configurer des alertes à $250
- 🔄 **Auto-scaling** : Réduire automatiquement pendant les heures creuses

## ⚠️ **Limitations pour le dev :**
- Pas de haute disponibilité (single point of failure)
- Performance réduite avec SPOT instances
- Pas de backup automatique
- Monitoring basique seulement

## 🎯 **Avantages :**
- ✅ Architecture identique à la production
- ✅ Vraie expérience Kubernetes
- ✅ Services managés AWS (RDS, MSK, ElastiCache)
- ✅ CI/CD compatible
- ✅ Évolutif vers la production

---

**Budget contrôlé : $200/mois pour un environnement de développement complet !** 🎉

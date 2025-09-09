# 💰 Analyse des Coûts AWS - Configuration Actuelle vs Free Tier

## ⚠️ **ATTENTION - Vous serez facturé avec la configuration actuelle !**

### 🔴 **Services qui DÉPASSENT le Free Tier :**

#### **1. Amazon EKS**
- **Configuration actuelle** : Cluster EKS
- **Coût** : $0.10/heure = **~$73/mois** pour le control plane
- **Free Tier** : ❌ **EKS n'est PAS inclus dans le free tier**

#### **2. Amazon RDS (4 instances MySQL)**
- **Configuration actuelle** : 4x db.t3.micro
- **Coût** : 4 instances = **~$50-60/mois**
- **Free Tier** : ✅ Seulement 1x db.t3.micro (750h/mois)

#### **3. Amazon MSK (Managed Kafka)**
- **Configuration actuelle** : 3 brokers kafka.t3.small
- **Coût** : **~$150-200/mois**
- **Free Tier** : ❌ **MSK n'est PAS inclus dans le free tier**

#### **4. ElastiCache Redis**
- **Configuration actuelle** : cache.t3.micro
- **Coût** : **~$15-20/mois**
- **Free Tier** : ❌ **ElastiCache n'est PAS inclus dans le free tier**

#### **5. EC2 Instances (Nodes EKS)**
- **Configuration actuelle** : 3x t3.medium
- **Coût** : **~$70-90/mois**
- **Free Tier** : ✅ Seulement 1x t2.micro (750h/mois)

### 💵 **Coût Total Estimé : $350-450/mois**

---

## ✅ **Solution FREE TIER - Configuration Alternative**

### **Option 1: Docker Compose Local (100% Gratuit)**
```bash
# Utiliser Docker Compose existant
docker-compose up -d
```
**Avantages :**
- ✅ 100% gratuit
- ✅ Configuration déjà existante
- ✅ Parfait pour développement/test

### **Option 2: AWS Free Tier Optimisé**

#### **Infrastructure Simplifiée :**
```terraform
# 1. Une seule EC2 t2.micro (Free Tier)
# 2. Une seule RDS db.t3.micro (Free Tier)  
# 3. Kafka/Redis en containers sur EC2
# 4. Pas d'EKS, juste Docker sur EC2
```

#### **Services Remplacés :**
- ❌ **EKS** → ✅ **EC2 t2.micro + Docker**
- ❌ **4x RDS** → ✅ **1x RDS + 3x MySQL containers**
- ❌ **MSK** → ✅ **Kafka container**
- ❌ **ElastiCache** → ✅ **Redis container**

---

## 🛠️ **Je peux créer une version Free Tier ?**

### **Voulez-vous que je crée :**

1. **🐳 Configuration Docker Compose simple** (Recommandé pour dev)
2. **☁️ Configuration AWS Free Tier optimisée** 
3. **📊 Estimation détaillée des coûts** de la config actuelle

---

## 📋 **Free Tier AWS - Limites actuelles :**

### **EC2** ✅
- 750 heures/mois de t2.micro
- 30 GB de stockage EBS

### **RDS** ✅  
- 750 heures/mois de db.t3.micro
- 20 GB de stockage

### **VPC/Networking** ✅
- VPC gratuit
- 1 GB de transfert sortant/mois

### **S3** ✅
- 5 GB de stockage
- 20,000 requêtes GET

### **❌ NON INCLUS dans Free Tier :**
- EKS Control Plane
- MSK (Kafka managé)
- ElastiCache
- Load Balancers ALB/NLB
- NAT Gateways

---

## 🚨 **RECOMMANDATION IMMÉDIATE**

**NE DÉPLOYEZ PAS** la configuration actuelle si vous voulez rester gratuit !

**Alternative recommandée :**
```bash
# Utiliser le Docker Compose existant
cd /home/otniel/springboot-kafka-microservices
docker-compose up -d
```

Cela vous donnera **exactement la même architecture** sans aucun coût AWS !

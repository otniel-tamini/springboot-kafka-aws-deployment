# 🎯 Configuration AWS FREE TIER pour Développement

Cette configuration vous permet de déployer vos microservices Spring Boot sur AWS **GRATUITEMENT** en respectant les limites du Free Tier.

## 💰 **Coût : $0.00/mois** (dans les limites du Free Tier)

### ✅ **Services utilisés (GRATUITS) :**
- **1x EC2 t2.micro** - 750h/mois gratuit
- **1x RDS db.t3.micro** - 750h/mois gratuit  
- **1x Elastic IP** - Gratuit quand attaché à une instance
- **VPC + Subnets** - Gratuits
- **1 GB transfert sortant** - Gratuit

### 🏗️ **Architecture simplifiée :**
```
Internet
    ↓
[EC2 t2.micro] ← Docker Compose
    ├── Service Registry (8761)
    ├── API Gateway (9191) 
    ├── Order Service (8080)
    ├── Payment Service (8085)
    ├── Product Service (8084)
    ├── Email Service (8086)
    ├── Identity Service (9898)
    ├── Kafka (conteneur)
    └── Redis (conteneur)
    ↓
[RDS MySQL] ← Base unique partagée
```

## 🚀 **Déploiement en 3 étapes :**

### **1. Générer une clé SSH**
```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/aws-dev-key
cat ~/.ssh/aws-dev-key.pub  # Copier le contenu
```

### **2. Configurer les variables**
```bash
cd terraform/environments/dev-freetier
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec votre clé SSH publique
```

### **3. Déployer**
```bash
terraform init
terraform plan
terraform apply
```

## 🎛️ **Accès aux services :**

Après le déploiement, tous vos services seront accessibles via :
- **Dashboard** : http://YOUR_IP/
- **Service Registry** : http://YOUR_IP:8761
- **API Gateway** : http://YOUR_IP:9191
- **Microservices** : http://YOUR_IP:8080-9898

## 📊 **Monitoring simple :**
```bash
# SSH vers le serveur
ssh -i ~/.ssh/aws-dev-key ec2-user@YOUR_IP

# Vérifier les services
docker-compose ps
docker-compose logs -f
```

## ⚠️ **Limites Free Tier à respecter :**
- ✅ **750h/mois EC2** (1 instance = ~31 jours)
- ✅ **750h/mois RDS** (1 instance = ~31 jours)  
- ✅ **20 GB stockage RDS** maximum
- ✅ **30 GB stockage EBS** maximum
- ✅ **1 GB transfert sortant/mois**

## 🔄 **Évolutivité :**
Cette configuration peut facilement évoluer vers la version production complète quand vous serez prêt à investir dans une infrastructure plus robuste.

---

**Avantage principal** : Architecture identique à la production, mais sur une seule machine pour rester gratuit ! 🎉

# =================================
# CONFIGURATION DES SECRETS GITHUB
# =================================

## Secrets requis pour les pipelines CI/CD

### 🔐 Secrets AWS (requis pour les deux pipelines)

```bash
# Accès AWS pour ECR et S3
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...

# URL du registre ECR (optionnel, par défaut dans variables)
ECR_REGISTRY_URL=123456789012.dkr.ecr.eu-west-1.amazonaws.com
```

### 📱 Secrets de notification (optionnels)

```bash
# Webhook Slack pour notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...

# Token Snyk pour scan de sécurité
SNYK_TOKEN=...
```

## 🔧 Variables GitHub

### Variables d'environnement (Settings > Environments)

#### Environment: `dev`
```
ECR_REGISTRY_URL=123456789012.dkr.ecr.eu-west-1.amazonaws.com
S3_BUCKET_PREFIX=ecommerce-dev
SLACK_WEBHOOK_URL=true
```

#### Environment: `staging`
```
ECR_REGISTRY_URL=123456789012.dkr.ecr.eu-west-1.amazonaws.com
S3_BUCKET_PREFIX=ecommerce-staging
SLACK_WEBHOOK_URL=true
```

#### Environment: `prod`
```
ECR_REGISTRY_URL=123456789012.dkr.ecr.eu-west-1.amazonaws.com
S3_BUCKET_PREFIX=ecommerce-prod
SLACK_WEBHOOK_URL=true
```

## 📋 Configuration des environnements

### 1. Créer les environnements GitHub

```bash
# Dans GitHub : Settings > Environments
# Repository: otniel-tamini/springboot-kafka-aws-deployment
# Créer : dev, staging, prod

# Pour chaque environnement, configurer :
- Protection rules (pour prod : require reviews)
- Environment secrets (spécifiques à l'env)
- Environment variables
```

### 2. Protection des branches

```yaml
# .github/branch-protection.yml
protection_rules:
  main:
    required_status_checks:
      strict: true
      contexts:
        - "🔍 Detect Changes"
        - "🏗️ Build Frontend"
        - "🐳 Build Microservices"
    enforce_admins: true
    required_pull_request_reviews:
      required_approving_review_count: 2
      dismiss_stale_reviews: true
      require_code_owner_reviews: true
    restrictions:
      users: []
      teams: ["platform-team"]
```

## 🚀 Déclenchement des pipelines

### Pipeline Frontend

```bash
# Automatique sur push vers main/develop avec changements dans frontend-app/
git add frontend-app/
git commit -m "feat: update frontend components"
git push origin main

# Manuel avec paramètres
# GitHub Actions > Frontend CI/CD > Run workflow
# - Environment: prod
# - Force deploy: true
```

### Pipeline Microservices

```bash
# Automatique sur push avec changements dans les services
git add order-service/
git commit -m "fix: update order validation"
git push origin main

# Manuel avec services spécifiques
# GitHub Actions > Microservices CI/CD > Run workflow
# - Services: order-service,payment-service
# - Environment: staging
# - Force build: false
```

## 📊 Monitoring et notifications

### Slack Integration

```yaml
# Channel: #deployments
# Notifications pour :
- Build success/failure
- Deployment status
- Security scan results
- Performance metrics
```

### GitHub Checks

```yaml
# Status checks créés automatiquement :
- Frontend Build Status
- Security Scan Results
- Test Coverage Report
- Docker Image Scan
- Deployment Verification
```

## 🛠️ Dépannage courant

### Erreur : ECR repository not found
```bash
# Solution : Créer le repo ECR manuellement ou via Terraform
aws ecr create-repository --repository-name api-gateway --region eu-west-1
```

### Erreur : S3 bucket not found
```bash
# Solution : Déployer l'infrastructure Terraform d'abord
cd terraform/environments/prod
terraform init && terraform apply
```

### Erreur : Permission denied pour ECR
```bash
# Solution : Vérifier les permissions IAM de l'utilisateur AWS
aws sts get-caller-identity
aws ecr get-login-password --region eu-west-1
```

### Build Maven fails
```bash
# Solution : Vérifier que common-lib est bien installé
# Le pipeline installe automatiquement common-lib avant build
```

## 📈 Métriques et optimisations

### Build time optimization
```yaml
# Cache Maven dependencies
# Cache Node modules
# Parallel builds pour microservices
# Incremental builds (only changed services)
```

### Cost optimization
```yaml
# Build seulement les services modifiés
# Cleanup des images Docker temporaires
# Retention policy pour les artifacts
# Compression des assets frontend
```

## 🔒 Sécurité

### Image scanning
```yaml
# Trivy pour scan de vulnérabilités
# Snyk pour dépendances
# OWASP dependency check pour Java
# npm audit pour Node.js
```

### Secrets rotation
```bash
# Rotation automatique recommandée tous les 90 jours
# Monitoring des accès AWS via CloudTrail
# Alertes sur utilisation anormale
```

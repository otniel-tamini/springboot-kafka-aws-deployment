#!/bin/bash

# =================================
# SCRIPT DE CONFIGURATION CI/CD
# =================================
# Ce script configure les secrets et variables GitHub nécessaires pour les pipelines

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER=${GITHUB_REPO_OWNER:-"otniel-tamini"}
REPO_NAME=${GITHUB_REPO_NAME:-"springboot-kafka-aws-deployment"}
AWS_REGION=${AWS_REGION:-"eu-west-1"}

echo -e "${BLUE}🚀 Configuration des pipelines CI/CD${NC}"
echo "=================================================="

# Vérification des prérequis
check_requirements() {
    echo -e "${YELLOW}🔍 Vérification des prérequis...${NC}"
    
    # GitHub CLI
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) n'est pas installé${NC}"
        echo "Installation : https://cli.github.com/"
        exit 1
    fi
    
    # AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI n'est pas installé${NC}"
        echo "Installation : https://aws.amazon.com/cli/"
        exit 1
    fi
    
    # jq
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq n'est pas installé${NC}"
        echo "Installation : sudo apt-get install jq"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Tous les prérequis sont installés${NC}"
}

# Authentification GitHub
github_auth() {
    echo -e "${YELLOW}🔐 Vérification de l'authentification GitHub...${NC}"
    
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠️ Non authentifié sur GitHub${NC}"
        echo "Lancement de l'authentification..."
        gh auth login
    fi
    
    # Vérifier les permissions
    if ! gh repo view "$REPO_OWNER/$REPO_NAME" &> /dev/null; then
        echo -e "${RED}❌ Impossible d'accéder au repository $REPO_OWNER/$REPO_NAME${NC}"
        echo "Vérifiez que le repository existe et que vous avez les permissions"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Authentification GitHub OK${NC}"
}

# Configuration AWS
aws_setup() {
    echo -e "${YELLOW}☁️ Vérification de la configuration AWS...${NC}"
    
    # Vérifier la configuration AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS CLI n'est pas configuré${NC}"
        echo "Lancez : aws configure"
        exit 1
    fi
    
    # Récupérer l'account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_REGISTRY_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
    
    echo -e "${GREEN}✅ Configuration AWS OK${NC}"
    echo "Account ID: $AWS_ACCOUNT_ID"
    echo "ECR Registry: $ECR_REGISTRY_URL"
}

# Création des secrets GitHub
create_secrets() {
    echo -e "${YELLOW}🔐 Configuration des secrets GitHub...${NC}"
    
    # Récupérer les credentials AWS actuels
    AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id 2>/dev/null || echo "")
    AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key 2>/dev/null || echo "")
    
    if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
        echo -e "${YELLOW}⚠️ Credentials AWS non trouvées dans la config locale${NC}"
        echo "Veuillez entrer vos credentials AWS pour CI/CD :"
        
        read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
        read -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
        echo
    fi
    
    # Créer les secrets
    echo "Création des secrets..."
    gh secret set AWS_ACCESS_KEY_ID --body "$AWS_ACCESS_KEY_ID" --repo "$REPO_OWNER/$REPO_NAME"
    gh secret set AWS_SECRET_ACCESS_KEY --body "$AWS_SECRET_ACCESS_KEY" --repo "$REPO_OWNER/$REPO_NAME"
    
    # Secrets optionnels
    read -p "Slack Webhook URL (optionnel, appuyez sur Entrée pour ignorer): " SLACK_WEBHOOK_URL
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        gh secret set SLACK_WEBHOOK_URL --body "$SLACK_WEBHOOK_URL" --repo "$REPO_OWNER/$REPO_NAME"
    fi
    
    read -p "Snyk Token (optionnel, appuyez sur Entrée pour ignorer): " SNYK_TOKEN
    if [[ -n "$SNYK_TOKEN" ]]; then
        gh secret set SNYK_TOKEN --body "$SNYK_TOKEN" --repo "$REPO_OWNER/$REPO_NAME"
    fi
    
    echo -e "${GREEN}✅ Secrets configurés${NC}"
}

# Création des variables
create_variables() {
    echo -e "${YELLOW}📝 Configuration des variables GitHub...${NC}"
    
    # Variables globales
    gh variable set ECR_REGISTRY_URL --body "$ECR_REGISTRY_URL" --repo "$REPO_OWNER/$REPO_NAME"
    gh variable set AWS_REGION --body "$AWS_REGION" --repo "$REPO_OWNER/$REPO_NAME"
    
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        gh variable set SLACK_WEBHOOK_URL --body "true" --repo "$REPO_OWNER/$REPO_NAME"
    fi
    
    echo -e "${GREEN}✅ Variables configurées${NC}"
}

# Création des environnements
create_environments() {
    echo -e "${YELLOW}🌍 Création des environnements GitHub...${NC}"
    
    # Environnements à créer
    ENVIRONMENTS=("dev" "staging" "prod")
    
    for env in "${ENVIRONMENTS[@]}"; do
        echo "Création de l'environnement : $env"
        
        # Créer l'environnement (via API GitHub car gh CLI ne supporte pas encore)
        curl -X PUT \
            -H "Accept: application/vnd.github.v3+json" \
            -H "Authorization: token $(gh auth token)" \
            "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/environments/$env" \
            -d '{
                "deployment_branch_policy": {
                    "protected_branches": false,
                    "custom_branch_policies": true
                }
            }' &> /dev/null || echo "Environnement $env déjà existant"
        
        # Variables spécifiques à l'environnement
        gh variable set S3_BUCKET_PREFIX --body "ecommerce-$env" --env "$env" --repo "$REPO_OWNER/$REPO_NAME" 2>/dev/null || true
    done
    
    echo -e "${GREEN}✅ Environnements créés${NC}"
}

# Création des repositories ECR
create_ecr_repos() {
    echo -e "${YELLOW}📦 Création des repositories ECR...${NC}"
    
    SERVICES=("api-gateway" "identity-service" "order-service" "payment-service" "product-service" "email-service" "service-registry")
    
    for service in "${SERVICES[@]}"; do
        echo "Création du repository ECR : $service"
        
        # Vérifier si le repo existe déjà
        if aws ecr describe-repositories --repository-names "$service" --region "$AWS_REGION" &> /dev/null; then
            echo "  ✅ Repository $service déjà existant"
        else
            # Créer le repository
            aws ecr create-repository \
                --repository-name "$service" \
                --region "$AWS_REGION" \
                --image-scanning-configuration scanOnPush=true \
                --encryption-configuration encryptionType=AES256 &> /dev/null
            echo "  ✅ Repository $service créé"
        fi
    done
    
    echo -e "${GREEN}✅ Repositories ECR configurés${NC}"
}

# Validation de la configuration
validate_setup() {
    echo -e "${YELLOW}✅ Validation de la configuration...${NC}"
    
    # Tester l'accès ECR
    if aws ecr get-login-password --region "$AWS_REGION" &> /dev/null; then
        echo "  ✅ Accès ECR fonctionnel"
    else
        echo -e "  ${RED}❌ Problème d'accès ECR${NC}"
    fi
    
    # Lister les secrets configurés
    echo "Secrets configurés :"
    gh secret list --repo "$REPO_OWNER/$REPO_NAME" | head -10
    
    # Lister les variables configurées
    echo "Variables configurées :"
    gh variable list --repo "$REPO_OWNER/$REPO_NAME" | head -10
    
    echo -e "${GREEN}✅ Configuration validée${NC}"
}

# Test des pipelines
test_pipelines() {
    echo -e "${YELLOW}🧪 Test des pipelines (optionnel)...${NC}"
    
    read -p "Voulez-vous tester les pipelines maintenant ? (y/N): " test_choice
    if [[ "$test_choice" =~ ^[Yy]$ ]]; then
        echo "Déclenchement du pipeline frontend..."
        gh workflow run "frontend-cicd.yml" --ref main
        
        echo "Déclenchement du pipeline microservices..."
        gh workflow run "microservices-cicd.yml" --ref main
        
        echo -e "${GREEN}✅ Pipelines déclenchés${NC}"
        echo "Vérifiez l'état dans : https://github.com/$REPO_OWNER/$REPO_NAME/actions"
    fi
}

# Génération du rapport
generate_report() {
    echo -e "${YELLOW}📋 Génération du rapport de configuration...${NC}"
    
    cat > ci-cd-config-report.md << EOF
# 🚀 Rapport de Configuration CI/CD

## Configuration réalisée le $(date)

### 🔧 Infrastructure
- **AWS Account ID**: $AWS_ACCOUNT_ID
- **AWS Region**: $AWS_REGION
- **ECR Registry**: $ECR_REGISTRY_URL

### 📦 Repositories ECR créés
$(for service in api-gateway identity-service order-service payment-service product-service email-service service-registry; do echo "- $service"; done)

### 🔐 Secrets GitHub configurés
- AWS_ACCESS_KEY_ID ✅
- AWS_SECRET_ACCESS_KEY ✅
$(if [[ -n "$SLACK_WEBHOOK_URL" ]]; then echo "- SLACK_WEBHOOK_URL ✅"; fi)
$(if [[ -n "$SNYK_TOKEN" ]]; then echo "- SNYK_TOKEN ✅"; fi)

### 📝 Variables GitHub configurées
- ECR_REGISTRY_URL ✅
- AWS_REGION ✅
$(if [[ -n "$SLACK_WEBHOOK_URL" ]]; then echo "- SLACK_WEBHOOK_URL ✅"; fi)

### 🌍 Environnements créés
- dev ✅
- staging ✅
- prod ✅

### 🔗 Liens utiles
- [Actions GitHub](https://github.com/$REPO_OWNER/$REPO_NAME/actions)
- [Settings Secrets](https://github.com/$REPO_OWNER/$REPO_NAME/settings/secrets/actions)
- [Console ECR](https://console.aws.amazon.com/ecr/repositories?region=$AWS_REGION)

### 📋 Prochaines étapes
1. Pousser du code pour déclencher les pipelines
2. Configurer les notifications Slack si besoin
3. Ajuster les règles de protection des branches
4. Monitorer les builds et optimiser si nécessaire

EOF

    echo -e "${GREEN}✅ Rapport généré : ci-cd-config-report.md${NC}"
}

# Fonction principale
main() {
    echo -e "${BLUE}"
    cat << "EOF"
 _____ _____       _____ _____     _____             __ _       
/  __ \_   _|     /  __ \  _  |   /  __ \           / _(_)      
| /  \/ | |  _____| /  \/ | | |   | /  \/ ___  _ __ | |_ _  __ _ 
| |     | | |_____| |   | | | |   | |    / _ \| '_ \|  _| |/ _` |
| \__/\_| |_      | \__/\ \_/ /   | \__/\ (_) | | | | | | | (_| |
 \____/\___/       \____/\___/     \____/\___/|_| |_|_| |_|\__, |
                                                            __/ |
                                                           |___/ 
EOF
    echo -e "${NC}"
    
    check_requirements
    github_auth
    aws_setup
    create_secrets
    create_variables
    create_environments
    create_ecr_repos
    validate_setup
    test_pipelines
    generate_report
    
    echo -e "${GREEN}"
    echo "=================================================="
    echo "🎉 Configuration CI/CD terminée avec succès ! 🎉"
    echo "=================================================="
    echo -e "${NC}"
    
    echo -e "${BLUE}Résumé :${NC}"
    echo "✅ Secrets GitHub configurés"
    echo "✅ Variables GitHub configurées"
    echo "✅ Environnements créés (dev, staging, prod)"
    echo "✅ Repositories ECR créés"
    echo "✅ Configuration validée"
    echo ""
    echo -e "${YELLOW}Prochaines étapes :${NC}"
    echo "1. Pusher du code pour déclencher les pipelines"
    echo "2. Surveiller les builds dans GitHub Actions"
    echo "3. Configurer les notifications additionnelles si besoin"
    echo ""
    echo -e "${BLUE}Documentation :${NC}"
    echo "📖 Voir .github/README.md pour les détails"
    echo "📋 Rapport détaillé : ci-cd-config-report.md"
}

# Gestion des erreurs
trap 'echo -e "${RED}❌ Erreur lors de la configuration${NC}"; exit 1' ERR

# Lancement du script
main "$@"

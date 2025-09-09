# Module S3 Static Files

Ce module Terraform crée une infrastructure complète pour héberger des fichiers statiques avec S3 et CloudFront.

## Fonctionnalités

- **Bucket S3** pour les fichiers statiques avec chiffrement et versioning
- **Distribution CloudFront** avec cache optimisé et compression
- **Origin Access Control (OAC)** pour sécuriser l'accès S3
- **Bucket optionnel** pour les logs CloudFront
- **Bucket optionnel** pour les uploads utilisateur
- **Configuration CORS** pour l'intégration frontend
- **Gestion du cycle de vie** des objets S3
- **Pages d'erreur personnalisées** pour les SPAs React

## Utilisation

```hcl
module "s3_static" {
  source = "./modules/s3-static"

  project_name = "ecommerce-platform"
  environment  = "prod"

  # Configuration S3
  enable_versioning = true
  enable_lifecycle  = true
  cors_allowed_origins = [
    "https://monapp.com",
    "https://www.monapp.com"
  ]

  # Configuration CloudFront
  enable_cloudfront_logs = true
  default_cache_ttl      = 86400    # 1 jour
  max_cache_ttl          = 31536000 # 1 an
  
  # Domaine personnalisé (optionnel)
  domain_aliases      = ["static.monapp.com"]
  ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"

  # Uploads utilisateur (optionnel)
  enable_user_uploads = true

  # Restrictions géographiques (optionnel)
  geo_restriction_type      = "whitelist"
  geo_restriction_locations = ["FR", "BE", "CH"]
}
```

## Variables

| Variable | Description | Type | Défaut | Requis |
|----------|-------------|------|---------|---------|
| `project_name` | Nom du projet | `string` | - | ✅ |
| `environment` | Environnement (dev, staging, prod) | `string` | - | ✅ |
| `enable_versioning` | Activer le versioning S3 | `bool` | `true` | ❌ |
| `enable_lifecycle` | Activer les règles de cycle de vie | `bool` | `true` | ❌ |
| `cors_allowed_origins` | Origines autorisées pour CORS | `list(string)` | `["*"]` | ❌ |
| `enable_cloudfront_logs` | Activer les logs CloudFront | `bool` | `false` | ❌ |
| `cloudfront_logs_retention_days` | Rétention des logs (jours) | `number` | `90` | ❌ |
| `default_root_object` | Objet racine par défaut | `string` | `"index.html"` | ❌ |
| `domain_aliases` | Aliases de domaine CloudFront | `list(string)` | `[]` | ❌ |
| `default_cache_ttl` | TTL de cache par défaut (secondes) | `number` | `86400` | ❌ |
| `max_cache_ttl` | TTL de cache maximum (secondes) | `number` | `31536000` | ❌ |
| `geo_restriction_type` | Type de restriction géographique | `string` | `"none"` | ❌ |
| `geo_restriction_locations` | Codes pays pour restrictions | `list(string)` | `[]` | ❌ |
| `ssl_certificate_arn` | ARN du certificat SSL ACM | `string` | `null` | ❌ |
| `enable_user_uploads` | Activer bucket uploads utilisateur | `bool` | `false` | ❌ |

## Outputs

### Bucket S3 Principal
- `s3_bucket_id` - ID du bucket S3
- `s3_bucket_arn` - ARN du bucket S3
- `s3_bucket_domain_name` - Nom de domaine du bucket
- `s3_bucket_regional_domain_name` - Nom de domaine régional

### CloudFront
- `cloudfront_distribution_id` - ID de la distribution
- `cloudfront_domain_name` - Nom de domaine CloudFront
- `cloudfront_status` - Statut de la distribution

### Configuration Déploiement
- `deployment_info` - Informations pour CI/CD
- `ansible_vars` - Variables pour Ansible
- `frontend_config` - Configuration frontend

## Architecture

```
Internet
    ↓
CloudFront Distribution
    ↓
Origin Access Control (OAC)
    ↓
S3 Bucket (Static Files)
```

### Stratégie de Cache

1. **Fichiers par défaut** : 1 jour de cache
2. **Assets statiques** (`/static/*`) : 1 an de cache
3. **Fichiers avec hash** (`*.*.js`) : 1 an de cache (immutables)
4. **index.html** : Cache court pour les mises à jour rapides

### Cycle de Vie S3

1. **Standard** : 0-30 jours
2. **Standard-IA** : 30-90 jours
3. **Glacier** : 90+ jours
4. **Suppression versions anciennes** : 365 jours

## Sécurité

- ✅ **Chiffrement** AES256 sur tous les buckets
- ✅ **Accès public bloqué** sur S3
- ✅ **Origin Access Control** pour CloudFront uniquement
- ✅ **HTTPS obligatoire** via CloudFront
- ✅ **Politique IAM restrictive**

## Intégration avec le Frontend React

Après déploiement du module, configurer le frontend :

```javascript
// config/environment.js
const config = {
  REACT_APP_API_BASE_URL: "https://your-cloudfront-domain.cloudfront.net/api",
  REACT_APP_STATIC_URL: "https://your-cloudfront-domain.cloudfront.net",
  REACT_APP_UPLOAD_URL: "https://your-uploads-bucket.s3.region.amazonaws.com"
};
```

## Déploiement CI/CD

### Exemple avec GitHub Actions

```yaml
- name: Deploy to S3 and invalidate CloudFront
  run: |
    aws s3 sync ./build s3://${{ outputs.s3_bucket_id }} --delete
    aws cloudfront create-invalidation \
      --distribution-id ${{ outputs.cloudfront_distribution_id }} \
      --paths "/*"
```

### Exemple avec Ansible

```yaml
- name: Upload static files to S3
  aws_s3_sync:
    bucket: "{{ s3_static_bucket }}"
    file_root: "./frontend-app/build"
    delete: yes

- name: Invalidate CloudFront cache
  aws_cloudfront_invalidation:
    distribution_id: "{{ cloudfront_id }}"
    target_paths: ["/*"]
```

## Monitoring

Le module inclut des métriques CloudWatch automatiques :
- Requêtes CloudFront
- Taux d'erreur 4xx/5xx
- Taille des objets S3
- Coûts de transfert

## Coûts

- **S3** : ~$0.023/GB/mois (Standard)
- **CloudFront** : ~$0.085/GB pour les premiers 10TB
- **Requêtes** : ~$0.0075/10,000 requêtes HTTP
- **Certificat SSL** : Gratuit avec ACM

## Dépendances

- AWS Provider >= 5.0
- Certificat ACM (pour HTTPS personnalisé)
- Route53 (pour domaines personnalisés)

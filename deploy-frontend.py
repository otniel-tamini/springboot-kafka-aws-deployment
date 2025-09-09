# =================================
# SCRIPT DE DÉPLOIEMENT FRONTEND S3
# =================================

import os
import subprocess
import sys
import json
import boto3
from pathlib import Path

def run_command(cmd, check=True):
    """Exécute une commande shell"""
    print(f"🔄 Exécution: {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"❌ Erreur: {result.stderr}")
        sys.exit(1)
    return result

def build_frontend():
    """Build le frontend React"""
    print("📦 Building du frontend React...")
    
    # Change to frontend directory
    os.chdir("../frontend-app")
    
    # Install dependencies
    run_command("npm install")
    
    # Build for production
    run_command("npm run build")
    
    print("✅ Frontend build terminé")

def upload_to_s3(bucket_name):
    """Upload les fichiers build vers S3"""
    print(f"📤 Upload vers S3 bucket: {bucket_name}")
    
    # Sync build directory to S3
    cmd = f"aws s3 sync build/ s3://{bucket_name}/ --delete --cache-control 'max-age=31536000,public' --exclude '*.html'"
    run_command(cmd)
    
    # Upload HTML files with different cache settings
    cmd = f"aws s3 sync build/ s3://{bucket_name}/ --delete --cache-control 'max-age=0,no-cache,no-store,must-revalidate' --exclude '*' --include '*.html'"
    run_command(cmd)
    
    print("✅ Upload S3 terminé")

def invalidate_cloudfront(distribution_id):
    """Invalide le cache CloudFront"""
    print(f"🔄 Invalidation CloudFront: {distribution_id}")
    
    cmd = f"aws cloudfront create-invalidation --distribution-id {distribution_id} --paths '/*'"
    result = run_command(cmd)
    
    print("✅ Invalidation CloudFront lancée")
    return json.loads(result.stdout)

def get_terraform_outputs():
    """Récupère les outputs Terraform"""
    print("📋 Récupération des outputs Terraform...")
    
    os.chdir("../terraform/environments/dev")
    result = run_command("terraform output -json")
    outputs = json.loads(result.stdout)
    
    return {
        'bucket_name': outputs['s3_bucket_name']['value'],
        'distribution_id': outputs['cloudfront_distribution_id']['value'],
        'cloudfront_url': outputs['cloudfront_url']['value']
    }

def main():
    """Fonction principale"""
    print("🚀 Déploiement du frontend vers S3/CloudFront")
    print("=" * 50)
    
    try:
        # Get Terraform outputs
        tf_outputs = get_terraform_outputs()
        
        # Build frontend
        build_frontend()
        
        # Upload to S3
        upload_to_s3(tf_outputs['bucket_name'])
        
        # Invalidate CloudFront
        invalidation = invalidate_cloudfront(tf_outputs['distribution_id'])
        
        print("\n🎉 Déploiement terminé avec succès!")
        print(f"📱 Frontend URL: {tf_outputs['cloudfront_url']}")
        print(f"🔄 Invalidation ID: {invalidation['Invalidation']['Id']}")
        print("\n⏳ Note: La propagation CloudFront peut prendre 5-15 minutes")
        
    except Exception as e:
        print(f"❌ Erreur lors du déploiement: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

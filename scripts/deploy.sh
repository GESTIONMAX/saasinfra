#!/bin/bash
# scripts/deploy.sh - Script de déploiement automatisé

set -e

echo "🚀 Déploiement GESTIONMAX SaaS Infrastructure"
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yml"
BACKUP_DIR="./backups"
LOG_FILE="./deploy.log"

# Functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> $LOG_FILE
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> $LOG_FILE
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Vérification des prérequis..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker n'est pas installé"
    fi
    
    if ! command -v docker compose &> /dev/null; then
        error "Docker Compose n'est pas installé"
    fi
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        error "Fichier $COMPOSE_FILE introuvable"
    fi
    
    log "✅ Prérequis validés"
}

# Create backup before deployment
create_backup() {
    if docker compose ps postgres | grep -q "Up"; then
        log "Création du backup avant déploiement..."
        mkdir -p $BACKUP_DIR
        
        backup_file="$BACKUP_DIR/pre-deploy-$(date +%Y%m%d_%H%M%S).sql"
        docker compose exec -T postgres pg_dump -U gestionmax gestionmax > "$backup_file"
        
        if [ $? -eq 0 ]; then
            log "✅ Backup créé: $backup_file"
        else
            warning "Échec du backup, continuer quand même? (y/N)"
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                error "Déploiement annulé"
            fi
        fi
    else
        log "PostgreSQL non démarré, pas de backup nécessaire"
    fi
}

# Create external networks
create_networks() {
    log "Création des réseaux Docker..."
    
    if ! docker network ls | grep -q "web"; then
        docker network create web
        log "✅ Réseau 'web' créé"
    else
        log "Réseau 'web' existe déjà"
    fi
}

# Deploy services
deploy_services() {
    log "Déploiement des services..."
    
    # Pull latest images
    log "Téléchargement des dernières images..."
    docker compose pull
    
    # Deploy with zero downtime
    log "Démarrage des services..."
    docker compose up -d --remove-orphans
    
    if [ $? -eq 0 ]; then
        log "✅ Services déployés avec succès"
    else
        error "Échec du déploiement des services"
    fi
}

# Health checks
health_checks() {
    log "Vérification de l'état des services..."
    
    services=("traefik" "prometheus" "grafana" "postgres" "redis")
    failed_services=()
    
    for service in "${services[@]}"; do
        if docker compose ps $service | grep -q "Up"; then
            log "✅ $service: OK"
        else
            failed_services+=($service)
            warning "$service: FAILED"
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log "✅ Tous les services sont opérationnels"
    else
        error "Services en échec: ${failed_services[*]}"
    fi
}

# Test endpoints
test_endpoints() {
    log "Test des endpoints..."
    
    endpoints=(
        "http://localhost:8081/dashboard/"
        "http://localhost:9092/-/healthy"
        "http://localhost:3002/api/health"
    )
    
    for endpoint in "${endpoints[@]}"; do
        if curl -f -s "$endpoint" > /dev/null; then
            log "✅ $endpoint: OK"
        else
            warning "$endpoint: Non accessible"
        fi
    done
}

# Cleanup old images
cleanup() {
    log "Nettoyage des anciennes images..."
    docker image prune -f
    log "✅ Nettoyage terminé"
}

# Main deployment flow
main() {
    log "Début du déploiement..."
    
    check_prerequisites
    create_backup
    create_networks
    deploy_services
    
    # Wait for services to start
    log "Attente du démarrage des services (30s)..."
    sleep 30
    
    health_checks
    test_endpoints
    cleanup
    
    log "🎉 Déploiement terminé avec succès!"
    echo ""
    echo "📊 Services disponibles:"
    echo "  - Traefik Dashboard: http://localhost:8081/dashboard/"
    echo "  - Grafana: http://localhost:3002 (admin/GestionMax2025!)"
    echo "  - Prometheus: http://localhost:9092"
    echo "  - Status Page: http://localhost:3001"
    echo ""
}

# Run deployment
main "$@"
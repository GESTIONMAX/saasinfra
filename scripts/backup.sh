#!/bin/bash
# scripts/backup.sh - Script de sauvegarde automatisé

set -e

BACKUP_DIR="./backups"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🔄 Sauvegarde GESTIONMAX - $TIMESTAMP"
echo "===================================="

# Create backup directory
mkdir -p $BACKUP_DIR

# PostgreSQL backup
echo "Sauvegarde PostgreSQL..."
docker compose exec -T postgres pg_dump -U gestionmax gestionmax > "$BACKUP_DIR/postgres_$TIMESTAMP.sql"

# Redis backup
echo "Sauvegarde Redis..."
docker compose exec -T redis redis-cli --rdb /data/dump_$TIMESTAMP.rdb
docker cp $(docker compose ps -q redis):/data/dump_$TIMESTAMP.rdb "$BACKUP_DIR/"

# Configuration backup
echo "Sauvegarde des configurations..."
tar -czf "$BACKUP_DIR/configs_$TIMESTAMP.tar.gz" \
    docker-compose.yml \
    traefik/ \
    monitoring/ \
    configs/ \
    .env 2>/dev/null || true

# Cleanup old backups
echo "Nettoyage des anciennes sauvegardes..."
find $BACKUP_DIR -name "*.sql" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.rdb" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "✅ Sauvegarde terminée: $BACKUP_DIR/"
ls -la $BACKUP_DIR/
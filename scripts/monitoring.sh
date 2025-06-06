#!/bin/bash
# scripts/monitoring.sh - Script de monitoring et diagnostics

set -e

echo "📊 Monitoring GESTIONMAX Infrastructure"
echo "======================================"

# System resources
echo "💻 Ressources système:"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)% utilisé"
echo "RAM: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " utilisé)"}')"
echo ""

# Docker resources
echo "🐳 Conteneurs Docker:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
echo ""

# Service status
echo "🔧 État des services:"
docker compose ps
echo ""

# Logs summary
echo "📝 Résumé des logs (dernières erreurs):"
docker compose logs --tail=10 | grep -i error || echo "Aucune erreur récente trouvée"
echo ""

# Database status
echo "👜 État de la base de données:"
docker compose exec -T postgres psql -U gestionmax -d gestionmax -c "SELECT version();" 2>/dev/null || echo "PostgreSQL non accessible"
docker compose exec -T postgres psql -U gestionmax -d gestionmax -c "SELECT count(*) as active_connections FROM pg_stat_activity;" 2>/dev/null || echo "Impossible de vérifier les connexions"
echo ""

# Network connectivity
echo "🌐 Connectivité réseau:"
curl -s -o /dev/null -w "Traefik Dashboard: %{http_code}\n" http://localhost:8081/dashboard/ || echo "Traefik: Non accessible"
curl -s -o /dev/null -w "Prometheus: %{http_code}\n" http://localhost:9092/-/healthy || echo "Prometheus: Non accessible"  
curl -s -o /dev/null -w "Grafana: %{http_code}\n" http://localhost:3002/api/health || echo "Grafana: Non accessible"
echo ""

# Disk space alerts
echo "💾 Alertes espace disque:"
df -h | awk 'NR>1 && +$5 > 80 {print "⚠️ ATTENTION: " $6 " utilise " $5 " de l\'espace disque"}'
df -h | awk 'NR>1 && +$5 > 90 {print "🔴 CRITIQUE: " $6 " utilise " $5 " de l\'espace disque"}'
echo ""

echo "✅ Monitoring terminé"
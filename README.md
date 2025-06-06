# GESTIONMAX SaaS Infrastructure

![GESTIONMAX](https://img.shields.io/badge/GESTIONMAX-Infrastructure-blue) ![Version](https://img.shields.io/badge/version-1.0.0-green) ![Docker](https://img.shields.io/badge/Docker-3.0+-blue) ![License](https://img.shields.io/badge/license-Private-red)

Infrastructure complète de surveillance, monitoring, logging et déploiement pour les applications SaaS de GESTIONMAX, basée sur Docker et des outils open-source de haute qualité.

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Architecture](#-architecture)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Monitoring](#-monitoring)
- [Logging](#-logging)
- [Backup](#-backup)
- [CI/CD](#-cicd)
- [Scripts](#-scripts)
- [Maintenance](#-maintenance)
- [Sécurité](#-sécurité)
- [FAQ](#-faq)
- [Licence](#-licence)

## 🔍 Vue d'ensemble

Cette infrastructure fournit une solution complète pour le déploiement, la surveillance et la gestion d'applications SaaS avec les fonctionnalités suivantes :

- **Reverse Proxy** : Traefik v3.0 avec auto-discovery et Let's Encrypt
- **Monitoring** : Prometheus, AlertManager, Grafana
- **Logging** : Loki, Promtail
- **Métriques** : Node Exporter, cAdvisor
- **Bases de données** : PostgreSQL, Redis avec exporters
- **Stockage d'objets** : MinIO
- **Uptime monitoring** : Uptime Kuma
- **Backup automatique** : PostgreSQL, Redis, Configurations
- **CI/CD** : GitHub Actions avec déploiement multi-environnements

## 🏗 Architecture

```
Client → Traefik (HTTPS) → Services
                ↓
┌───────────────┬──────────────┬─────────────┐
│ Applications  │ Monitoring   │ Databases   │
│               │ & Logging    │ & Storage   │
└───────────────┴──────────────┴─────────────┘
```

### Composants

- **Traefik** : Reverse proxy, équilibreur de charge, terminaison SSL
- **Prometheus** : Collection de métriques et alerting
- **AlertManager** : Gestion et routage des alertes
- **Grafana** : Tableaux de bord et visualisation
- **Loki & Promtail** : Agrégation de logs
- **PostgreSQL** : Base de données relationnelle
- **Redis** : Cache et stockage clé-valeur
- **MinIO** : Stockage d'objets compatible S3
- **Uptime Kuma** : Surveillance de disponibilité et alertes

## 🛠 Prérequis

- Docker Engine 24.0+ et Docker Compose v2
- Un serveur Linux avec au moins 4Go de RAM et 20Go d'espace disque
- Un nom de domaine configuré avec accès DNS
- Ports 80 et 443 accessibles

## 🚀 Installation

### Étape 1 : Cloner le dépôt

```bash
git clone https://github.com/gestionmax/saasinfra.git
cd saasinfra
```

### Étape 2 : Configurer les variables d'environnement

```bash
cp .env.example .env
# Éditez le fichier .env avec vos valeurs
nano .env
```

### Étape 3 : Créer le réseau Docker externe

```bash
docker network create web
```

### Étape 4 : Lancer l'infrastructure

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## ⚙️ Configuration

### Structure des fichiers

```
.
├── docker-compose.yml           # Configuration des services
├── .env                         # Variables d'environnement
├── .github/workflows/           # Pipelines CI/CD
├── traefik/                     # Configuration de Traefik
├── monitoring/                  # Prometheus, AlertManager, etc.
│   ├── prometheus.yml
│   ├── alertmanager.yml
│   ├── rules/                   # Règles d'alerte
│   ├── grafana/                 # Dashboards et datasources
│   ├── loki-config.yml
│   └── promtail-config.yml
├── scripts/                     # Scripts utilitaires
└── backups/                     # Dossier pour les backups
```

### Personnalisation des domaines

Modifiez les labels `traefik.http.routers.*.rule` dans le fichier `docker-compose.yml` pour utiliser vos propres domaines.

### Sécurité et mots de passe

Modifiez le fichier `.env` pour définir des mots de passe sécurisés pour tous les services.

## 📊 Monitoring

### Dashboards Grafana

Accédez à Grafana via `https://dashboard.gestionmax.fr` avec les identifiants configurés dans le fichier `.env`.

Dashboards disponibles :
- Infrastructure Overview
- Docker Containers
- PostgreSQL
- Redis
- Traefik

### Prometheus

Accédez à l'interface de Prometheus via `https://metrics.gestionmax.fr`.

### Alerting

Les alertes sont configurées dans `monitoring/rules/alerts.yml` et routées via AlertManager.
Vous pouvez configurer les notifications Slack dans `monitoring/alertmanager.yml`.

## 📝 Logging

Les logs sont collectés par Promtail et stockés dans Loki. Vous pouvez les visualiser dans Grafana.

### Requêtes courantes

```
{container_name=~"gestionmax_.*"} # Tous les logs des conteneurs GESTIONMAX
{container_name="gestionmax_traefik"} # Logs de Traefik
{level="error"} # Tous les logs d'erreur
```

## 💾 Backup

Les backups sont gérés par le script `scripts/backup.sh` et exécutés quotidiennement pour :
- Base de données PostgreSQL
- Données Redis
- Fichiers de configuration

Les backups sont stockés dans le dossier `backups/` avec une politique de rétention de 7 jours par défaut.

## 🔄 CI/CD

Le pipeline CI/CD est configuré via GitHub Actions dans `.github/workflows/ci-cd.yml` et comprend :

1. **Validation** : Vérification de la syntaxe et des fichiers requis
2. **Tests de sécurité** : Analyse avec Trivy et TruffleHog
3. **Tests d'intégration** : Vérification du démarrage des services
4. **Déploiement staging** : Pour la branche `develop`
5. **Déploiement production** : Pour la branche `main`

### Configuration requise

Dans les secrets GitHub du dépôt, configurez :
- `STAGING_SSH_KEY`, `STAGING_HOST`, `STAGING_USER`
- `PROD_SSH_KEY`, `PROD_HOST`, `PROD_USER`
- `SLACK_WEBHOOK`

## 📜 Scripts

### deploy.sh

Script de déploiement avec vérification des prérequis, backup préalable, et tests de santé.

```bash
./scripts/deploy.sh [--no-backup] [--force-recreate]
```

### backup.sh

Crée des backups des bases de données et configurations.

```bash
./scripts/backup.sh [--no-postgres] [--no-redis] [--retention=7]
```

### monitoring.sh

Affiche l'état actuel du système et des services.

```bash
./scripts/monitoring.sh [--full] [--logs]
```

## 🔧 Maintenance

### Mise à jour des services

Pour mettre à jour les services avec les dernières images :

```bash
./scripts/deploy.sh --pull
```

### Vérification de l'état

```bash
./scripts/monitoring.sh --full
```

### Résolution des problèmes courants

- **Service ne démarre pas** : Vérifiez les logs avec `docker compose logs [service]`
- **Problèmes de certificat** : Vérifiez les logs de Traefik et assurez-vous que les ports 80/443 sont accessibles
- **Alertes persistantes** : Vérifiez la configuration dans `monitoring/rules/alerts.yml`

## 🔒 Sécurité

### Bonnes pratiques

- Utilisez des mots de passe forts et uniques pour chaque service
- Limitez l'accès aux interfaces d'administration par IP
- Vérifiez régulièrement les vulnérabilités avec `./scripts/deploy.sh --scan`

### Hardening

Pour renforcer la sécurité de l'infrastructure :

1. Configurez un pare-feu (UFW) pour limiter l'accès aux ports
2. Utilisez Docker Secrets au lieu de variables d'environnement
3. Activez l'authentification à deux facteurs pour Grafana

## ❓ FAQ

**Q: Comment ajouter un nouveau service au monitoring ?**

R: Ajoutez une nouvelle configuration de scraping dans `monitoring/prometheus.yml` et redémarrez Prometheus.

**Q: Comment créer un nouveau dashboard Grafana ?**

R: Créez un fichier JSON dans `monitoring/grafana/dashboards/` et redémarrez Grafana.

**Q: Comment restaurer un backup ?**

R: Utilisez les commandes suivantes :
```bash
cat backups/backup_YYYYMMDD_HHMMSS.sql | docker exec -i gestionmax_postgres psql -U gestionmax -d gestionmax
```

## 📄 Licence

Ce projet est sous licence privée. Tous droits réservés à GESTIONMAX © 2025.

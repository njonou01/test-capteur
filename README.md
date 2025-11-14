# 🚪 Entrance Cockpit - Système de Contrôle d'Accès

![Java](https://img.shields.io/badge/Java-21-orange)
![Micronaut](https://img.shields.io/badge/Micronaut-4.2.3-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)
![Redis](https://img.shields.io/badge/Redis-7-red)
![Kafka](https://img.shields.io/badge/Kafka-7.5-black)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![License](https://img.shields.io/badge/License-MIT-green)

Application d'entreprise de contrôle d'accès sécurisé avec architecture microservices, authentification JWT, journalisation centralisée et contrôle de serrures intelligentes via HTTPS.

---

## 📋 Table des Matières

- [Architecture](#-architecture)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#️-configuration)
- [Démarrage](#-démarrage)
- [Services Backend](#-services-backend)
- [Sécurité](#-sécurité)
- [API Endpoints](#-api-endpoints)
- [Développement](#-développement)
- [Tests](#-tests)
- [Production](#-production)
- [Troubleshooting](#-troubleshooting)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENTRANCE COCKPIT FRONT                       │
│                   (React.js + Tailwind CSS)                     │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTPS
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                  TRAEFIK (Reverse Proxy HTTPS)                  │
│   - TLS/SSL (Self-Signed) - Rate Limiting - Load Balancing     │
└──┬──────────┬──────────┬──────────┬──────────┬─────────────────┘
   │ :8080    │ :8081    │ :8082    │ :8083    │ :8084
   ▼          ▼          ▼          ▼          ▼
┌──────────┐ ┌──────────┐ ┌─────────────┐ ┌──────────────┐ ┌──────────┐
│ STATIC   │ │  CORE    │ │   CACHE     │ │  ENTRANCE    │ │TELEMETRY │
│ SERVER   │ │OPERATION │ │  LOADING    │ │  COCKPIT     │ │  TO MSG  │
│BACKEND   │ │BACKEND   │ │  BACKEND    │ │  BACKEND     │ │BACKEND   │
└──────────┘ └──────────┘ └─────────────┘ └──────────────┘ └──────────┘
                 │              │                │                │
     ┌───────────┴──────────────┴────────────────┴────────────────┘
     │
     ▼
┌────────────────────────────────────────────────┐
│  PostgreSQL │ Redis │ Kafka │ MQTT Broker      │
│   Database  │ Cache │ Events│ (Télémétrie)     │
└────────────────────────────────────────────────┘
```

### 🎯 Microservices

1. **Static Server Backend** (Port 8080)
   - Sert le frontend React compilé
   - Gestion des assets statiques
   - Headers de cache optimisés

2. **Core Operational Backend** (Port 8081)
   - Authentification & autorisation (JWT)
   - Validation d'accès via Redis
   - Contrôle des entrées (Activate/Reject)

3. **Cache Loading Backend** (Port 8082)
   - Synchronisation PostgreSQL ↔ Redis
   - Invalidation intelligente du cache
   - Métriques et monitoring

4. **Entrance Cockpit Backend** (Port 8083)
   - Gestion des requêtes d'entrée
   - Logs temps réel (WebSocket)
   - Autorisation manuelle

5. **Telemetry Messaging Backend** (Port 8084)
   - Télémétrie des capteurs IoT
   - Contrôle des serrures (MQTT/WebSocket)
   - Événements Kafka

---

## 📦 Prérequis

### Système
- **OS**: Linux, macOS, ou Windows (avec WSL2)
- **RAM**: Minimum 8 GB (16 GB recommandé)
- **Disk**: 10 GB espace libre

### Logiciels
- **Docker**: >= 24.0
- **Docker Compose**: >= 2.20
- **Java**: 21 (pour développement local)
- **Maven**: >= 3.9 (pour développement local)
- **Node.js**: >= 20 (pour le frontend)

### Vérification
```bash
docker --version
docker compose version
java -version
mvn -version
node -v
```

---

## 🚀 Installation

### 1. Cloner le projet
```bash
git clone https://github.com/votre-username/entrance-cockpit.git
cd entrance-cockpit
```

### 2. Configuration des variables d'environnement
```bash
cp .env.example .env
```

Éditez `.env` et changez les valeurs sensibles :
```bash
# Générer un secret JWT fort
openssl rand -base64 32

# Changez les mots de passe
POSTGRES_PASSWORD=<votre-mot-de-passe-fort>
REDIS_PASSWORD=<votre-mot-de-passe-fort>
JWT_SECRET=<votre-secret-jwt-généré>
```

### 3. Générer les certificats SSL (auto-signés pour dev)
```bash
cd docker/traefik/certs
chmod +x generate-certs.sh
./generate-certs.sh localhost 365
cd ../../..
```

Pour faire confiance aux certificats auto-signés :
```bash
# Linux
sudo cp docker/traefik/certs/ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# macOS
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  docker/traefik/certs/ca.crt
```

### 4. Build les services Java
```bash
mvn clean install -DskipTests
```

---

## ⚙️ Configuration

### Fichiers de configuration principaux

| Fichier | Description |
|---------|-------------|
| `.env` | Variables d'environnement |
| `docker-compose.yml` | Orchestration des services |
| `docker/traefik/traefik.yml` | Configuration Traefik |
| `docker/traefik/dynamic/tls.yml` | Middlewares & TLS |
| `docker/postgres/init.sql` | Schéma de base de données |

### Configuration de la base de données

Le schéma PostgreSQL est automatiquement créé au démarrage via `init.sql`.

**Utilisateurs par défaut** (password: `Admin123!`):
- **admin** - Super Admin
- **security** - Security Officer
- **john.doe** - Utilisateur standard

**Badges par défaut**:
- `BADGE-001` - Admin (accès niveau 4)
- `BADGE-002` - Security (accès niveau 3)
- `BADGE-003` - User (accès niveau 1)

---

## 🎬 Démarrage

### Démarrage complet (Production-like)
```bash
docker compose up -d
```

### Démarrage avec logs
```bash
docker compose up
```

### Vérification de l'état
```bash
docker compose ps
```

### Arrêt
```bash
docker compose down
```

### Arrêt + suppression des volumes (reset complet)
```bash
docker compose down -v
```

---

## 🔧 Services Backend

### URLs d'accès

| Service | URL | Dashboard |
|---------|-----|-----------|
| **Frontend** | https://localhost | - |
| **Traefik Dashboard** | http://localhost:8090 | ✅ |
| **Static Server** | https://localhost:8080/health | - |
| **Core Operational** | https://localhost:8081/health | - |
| **Cache Loading** | https://localhost:8082/health | - |
| **Entrance Cockpit** | https://localhost:8083/health | - |
| **Telemetry** | https://localhost:8084/health | - |

### Logs
```bash
# Tous les services
docker compose logs -f

# Service spécifique
docker compose logs -f core-operational-backend

# Dernières 100 lignes
docker compose logs --tail=100 entrance-cockpit-backend
```

### Restart un service
```bash
docker compose restart core-operational-backend
```

### Rebuild un service
```bash
docker compose up -d --build core-operational-backend
```

---

## 🔐 Sécurité

### Mesures de sécurité implémentées

- ✅ **HTTPS/TLS** - Tout le trafic chiffré via Traefik
- ✅ **JWT Tokens** - Authentification stateless avec expiration
- ✅ **Password Hashing** - BCrypt avec salt
- ✅ **Rate Limiting** - Protection contre le brute-force
- ✅ **CORS** - Restrictions cross-origin
- ✅ **Security Headers** - HSTS, CSP, X-Frame-Options
- ✅ **Input Validation** - Bean Validation sur tous les endpoints
- ✅ **Audit Logging** - Traçabilité complète
- ✅ **SQL Injection Protection** - Requêtes paramétrées (JPA)

### Configuration JWT

Éditer dans `.env`:
```bash
JWT_SECRET=<généré-avec-openssl-rand-base64-32>
JWT_EXPIRATION=3600  # 1 heure en secondes
```

### Audit Logs

Tous les événements critiques sont enregistrés dans `audit_logs`:
- Connexions/déconnexions
- Tentatives d'accès
- Modifications de données sensibles
- Erreurs d'authentification

Requête exemple:
```sql
SELECT * FROM audit_logs
WHERE user_id = 1
ORDER BY created_at DESC
LIMIT 50;
```

---

## 📡 API Endpoints

### Authentification

#### Login
```bash
POST /api/auth/login
Content-Type: application/json

{
  "badgeId": "BADGE-001",
  "password": "Admin123!"
}

# Response
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600,
  "user": {
    "id": 1,
    "username": "admin",
    "role": "SUPER_ADMIN"
  }
}
```

#### Validate Token
```bash
POST /api/auth/validate
Authorization: Bearer <token>

# Response
{
  "valid": true,
  "user": {...}
}
```

### Entrance Control

#### Badge Scan (depuis IoT)
```bash
POST /api/entrance/badge-scan
Content-Type: application/json

{
  "badgeId": "BADGE-001",
  "location": "Main Entrance",
  "deviceId": "READER-001"
}
```

#### Manual Authorization
```bash
POST /api/entrance/manual-authorize
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "entryRequestId": 123,
  "notes": "Approved by admin"
}
```

#### Real-time Logs (WebSocket)
```javascript
const ws = new WebSocket('wss://localhost/ws/entrance-realtime');

ws.onmessage = (event) => {
  const entryEvent = JSON.parse(event.data);
  console.log('New entry:', entryEvent);
};
```

### Cache Management

#### Warmup Cache
```bash
POST /api/cache/warmup
Authorization: Bearer <admin-token>
```

#### Cache Statistics
```bash
GET /api/cache/stats
Authorization: Bearer <admin-token>

# Response
{
  "keys": 1523,
  "memory": "45.2 MB",
  "hitRate": 98.7
}
```

### Telemetry

#### Door Lock Control
```bash
POST /api/door-locks/control
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "lockId": "LOCK-001",
  "command": "UNLOCK"
}
```

#### Sensor Data
```bash
GET /api/telemetry/sensors
Authorization: Bearer <token>

# Response
{
  "sensors": [
    {
      "sensorId": "TEMP-001",
      "type": "TEMPERATURE",
      "value": 22.5,
      "unit": "°C",
      "status": "NORMAL"
    }
  ]
}
```

---

## 💻 Développement

### Structure du projet
```
entrance-cockpit/
├── backend/                    # Services Micronaut
│   ├── static-server-backend/
│   ├── core-operational-backend/
│   ├── cache-loading-backend/
│   ├── entrance-cockpit-backend/
│   └── telemetry-messaging-backend/
├── frontend/                   # React App
├── docker/                     # Docker configs
│   ├── postgres/
│   ├── traefik/
│   └── kafka/
├── iot-simulator/              # Simulateur IoT
└── docker-compose.yml
```

### Développement local (sans Docker)

#### 1. Démarrer l'infrastructure
```bash
docker compose up -d postgres redis kafka
```

#### 2. Compiler les services
```bash
mvn clean package -DskipTests
```

#### 3. Lancer un service
```bash
cd backend/core-operational-backend
mvn mn:run
```

#### 4. Hot reload (avec Maven)
```bash
mvn compile exec:java -Dexec.mainClass="com.entrancecockpit.core.CoreOperationalApplication"
```

### Frontend (React)
```bash
cd frontend
npm install
npm run dev
```

---

## 🧪 Tests

### Tests unitaires
```bash
mvn test
```

### Tests d'intégration
```bash
mvn verify
```

### Tests d'un service spécifique
```bash
cd backend/core-operational-backend
mvn test
```

### Coverage
```bash
mvn clean verify jacoco:report
```

---

## 🚢 Production

### Recommandations pour la production

#### 1. Utiliser Let's Encrypt au lieu des certificats auto-signés

Éditez `docker/traefik/traefik.yml`:
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@votre-domaine.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

#### 2. Renforcer les mots de passe
```bash
# Générer des secrets forts
openssl rand -base64 32  # JWT_SECRET
openssl rand -base64 24  # POSTGRES_PASSWORD
openssl rand -base64 24  # REDIS_PASSWORD
```

#### 3. Désactiver les dashboards publics
```yaml
# docker-compose.yml
TRAEFIK_API_INSECURE=false
```

#### 4. Configurer les backups PostgreSQL
```bash
# Backup quotidien
0 2 * * * docker exec entrance-postgres pg_dump -U entrance_user entrance_db > /backups/entrance_db_$(date +\%Y\%m\%d).sql
```

#### 5. Monitoring & Alerting
- Intégrer Prometheus/Grafana
- Configurer les alertes sur les métriques critiques
- Surveiller les logs Kafka

---

## 🔍 Troubleshooting

### Problème: Certificat SSL non reconnu
**Solution**:
```bash
# Régénérer les certificats
cd docker/traefik/certs
./generate-certs.sh localhost 365

# Importer dans le système
sudo cp ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

### Problème: Kafka ne démarre pas
**Solution**:
```bash
# Supprimer les volumes Kafka
docker compose down -v
docker volume rm entrance-cockpit_kafka-data
docker compose up -d kafka
```

### Problème: Connection refused à PostgreSQL
**Solution**:
```bash
# Vérifier que PostgreSQL est bien démarré
docker compose ps postgres

# Vérifier les logs
docker compose logs postgres

# Restart
docker compose restart postgres
```

### Problème: Port déjà utilisé
**Solution**:
```bash
# Identifier le processus
sudo lsof -i :8080

# Tuer le processus
kill -9 <PID>
```

### Problème: Out of Memory
**Solution**:
```bash
# Augmenter la mémoire Docker
# Docker Desktop > Settings > Resources > Memory: 8GB minimum

# Ou limiter les services
docker compose up -d postgres redis kafka core-operational-backend
```

---

## 📚 Documentation additionnelle

- [Micronaut Documentation](https://docs.micronaut.io/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## 👥 Contributeurs

- **Votre Nom** - Lead Developer

---

## 📄 License

MIT License - voir [LICENSE](LICENSE) pour plus de détails.

---

## 🎓 Projet de Classe

Ce projet a été développé dans le cadre d'un cours sur les architectures microservices et la sécurité des systèmes d'information.

**École**: [Nom de votre école]
**Cours**: Architecture Microservices & Sécurité
**Année**: 2025

---

**🚀 Happy Coding!**

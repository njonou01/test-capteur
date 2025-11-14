# test-capteur

Projet de test et monitoring de capteurs IoT

## Table des matières

- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Déploiement](#déploiement)
  - [Déploiement local](#déploiement-local)
  - [Déploiement avec Docker](#déploiement-avec-docker)
  - [Déploiement sur Raspberry Pi](#déploiement-sur-raspberry-pi)
  - [Déploiement sur serveur Cloud](#déploiement-sur-serveur-cloud)
- [Tests](#tests)
- [Monitoring](#monitoring)
- [Maintenance](#maintenance)
- [Dépannage](#dépannage)

## Prérequis

### Matériel
- Raspberry Pi 3/4 (recommandé) ou tout système Linux
- Capteurs compatibles (température, humidité, pression, etc.)
- Connexion réseau (WiFi ou Ethernet)
- Alimentation stable 5V/3A

### Logiciels
- Python 3.8 ou supérieur
- pip (gestionnaire de paquets Python)
- Git
- Docker et Docker Compose (optionnel mais recommandé)
- Node.js 16+ (si interface web)

## Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/njonou01/test-capteur.git
cd test-capteur
```

### 2. Créer un environnement virtuel Python

```bash
python3 -m venv venv
source venv/bin/activate  # Sur Linux/Mac
# ou
venv\Scripts\activate  # Sur Windows
```

### 3. Installer les dépendances

```bash
pip install -r requirements.txt
```

### 4. Installer les dépendances système (Raspberry Pi)

```bash
sudo apt-get update
sudo apt-get install -y python3-dev python3-pip git i2c-tools
sudo raspi-config  # Activer I2C et SPI dans Interfacing Options
```

## Configuration

### 1. Fichier de configuration

Copier le fichier de configuration exemple :

```bash
cp config.example.yml config.yml
```

### 2. Éditer la configuration

Éditer `config.yml` avec vos paramètres :

```yaml
# Configuration des capteurs
capteurs:
  temperature:
    type: "DHT22"
    pin: 4
    intervalle: 60  # secondes

  pression:
    type: "BMP280"
    i2c_address: "0x76"
    intervalle: 60

# Configuration réseau
network:
  mqtt_broker: "localhost"
  mqtt_port: 1883
  mqtt_user: ""
  mqtt_password: ""

# Configuration base de données
database:
  type: "influxdb"  # ou "postgresql", "sqlite"
  host: "localhost"
  port: 8086
  name: "capteurs_db"
  user: "admin"
  password: "changeme"

# Configuration logging
logging:
  level: "INFO"
  file: "/var/log/test-capteur/app.log"
```

### 3. Variables d'environnement

Créer un fichier `.env` pour les données sensibles :

```bash
cp .env.example .env
```

Éditer le fichier `.env` :

```
DB_PASSWORD=votre_mot_de_passe_secret
MQTT_PASSWORD=votre_mqtt_password
API_KEY=votre_api_key
```

## Déploiement

### Déploiement local

#### 1. Démarrage manuel

```bash
# Activer l'environnement virtuel
source venv/bin/activate

# Lancer l'application
python src/main.py
```

#### 2. Démarrage avec systemd (production)

Créer un service systemd `/etc/systemd/system/test-capteur.service` :

```ini
[Unit]
Description=Test Capteur Service
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/test-capteur
Environment="PATH=/home/pi/test-capteur/venv/bin"
ExecStart=/home/pi/test-capteur/venv/bin/python src/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Activer et démarrer le service :

```bash
sudo systemctl daemon-reload
sudo systemctl enable test-capteur
sudo systemctl start test-capteur
sudo systemctl status test-capteur
```

### Déploiement avec Docker

#### 1. Construction de l'image

```bash
docker build -t test-capteur:latest .
```

#### 2. Lancement avec Docker Compose

```bash
docker-compose up -d
```

#### 3. Vérifier les logs

```bash
docker-compose logs -f
```

#### 4. Arrêter les services

```bash
docker-compose down
```

### Déploiement sur Raspberry Pi

#### 1. Préparation du Raspberry Pi

```bash
# Mettre à jour le système
sudo apt-get update && sudo apt-get upgrade -y

# Installer Docker (optionnel)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker pi

# Installer Docker Compose
sudo apt-get install -y docker-compose
```

#### 2. Configuration des permissions GPIO

```bash
sudo usermod -aG gpio pi
sudo usermod -aG i2c pi
```

#### 3. Activer les interfaces nécessaires

```bash
sudo raspi-config
# Naviguer vers : Interface Options > I2C > Enable
# Naviguer vers : Interface Options > SPI > Enable
sudo reboot
```

#### 4. Déploiement

Suivre les étapes de [Déploiement local](#déploiement-local) ou [Déploiement avec Docker](#déploiement-avec-docker)

### Déploiement sur serveur Cloud

#### Option 1 : Déploiement sur VPS (DigitalOcean, AWS EC2, etc.)

```bash
# 1. Se connecter au serveur
ssh user@votre-serveur.com

# 2. Installer les dépendances
sudo apt-get update
sudo apt-get install -y git python3-pip docker.io docker-compose

# 3. Cloner le projet
git clone https://github.com/njonou01/test-capteur.git
cd test-capteur

# 4. Configurer et démarrer
cp .env.example .env
# Éditer .env avec vos configurations
docker-compose up -d
```

#### Option 2 : Déploiement sur Kubernetes

```bash
# 1. Appliquer les configurations
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# 2. Vérifier le déploiement
kubectl get pods -n test-capteur
kubectl logs -f deployment/test-capteur -n test-capteur
```

#### Option 3 : Déploiement sur Heroku

```bash
# 1. Installer Heroku CLI
curl https://cli-assets.heroku.com/install.sh | sh

# 2. Se connecter
heroku login

# 3. Créer une application
heroku create test-capteur-app

# 4. Configurer les variables d'environnement
heroku config:set DB_PASSWORD=votre_password
heroku config:set MQTT_PASSWORD=votre_mqtt_password

# 5. Déployer
git push heroku main
```

## Tests

### Tests unitaires

```bash
# Installer les dépendances de test
pip install -r requirements-dev.txt

# Lancer les tests
pytest tests/

# Avec couverture
pytest --cov=src tests/
```

### Tests d'intégration

```bash
# Tester la connexion aux capteurs
python tests/test_sensors.py

# Tester la connexion MQTT
python tests/test_mqtt.py

# Tester la base de données
python tests/test_database.py
```

### Tests de production

```bash
# Vérifier que le service fonctionne
curl http://localhost:8000/health

# Vérifier les logs
tail -f /var/log/test-capteur/app.log

# Ou avec Docker
docker-compose logs -f
```

## Monitoring

### 1. Vérifier l'état du service

```bash
# Avec systemd
sudo systemctl status test-capteur

# Avec Docker
docker-compose ps
```

### 2. Surveillance des logs

```bash
# Logs en temps réel
tail -f /var/log/test-capteur/app.log

# Avec Docker
docker-compose logs -f --tail=100
```

### 3. Métriques système

```bash
# Utilisation CPU et mémoire
htop

# Avec Docker
docker stats
```

### 4. Dashboard de monitoring (optionnel)

Configuration avec Grafana + InfluxDB :

```bash
# Démarrer le stack de monitoring
docker-compose -f docker-compose.monitoring.yml up -d

# Accéder à Grafana
# URL: http://localhost:3000
# User: admin / Password: admin
```

## Maintenance

### Mise à jour du code

```bash
# 1. Arrêter le service
sudo systemctl stop test-capteur
# ou
docker-compose down

# 2. Récupérer les mises à jour
git pull origin main

# 3. Mettre à jour les dépendances
pip install -r requirements.txt --upgrade
# ou
docker-compose build

# 4. Redémarrer le service
sudo systemctl start test-capteur
# ou
docker-compose up -d
```

### Sauvegarde des données

```bash
# Sauvegarder la base de données
./scripts/backup_db.sh

# Sauvegarder les configurations
tar -czf config-backup-$(date +%Y%m%d).tar.gz config.yml .env
```

### Rotation des logs

Créer `/etc/logrotate.d/test-capteur` :

```
/var/log/test-capteur/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 pi pi
}
```

## Dépannage

### Le service ne démarre pas

```bash
# Vérifier les logs
journalctl -u test-capteur -n 50 --no-pager

# Vérifier les permissions
ls -la /home/pi/test-capteur
```

### Problèmes de capteurs

```bash
# Vérifier les périphériques I2C
i2cdetect -y 1

# Vérifier les GPIO
gpio readall
```

### Problèmes réseau/MQTT

```bash
# Tester la connexion MQTT
mosquitto_sub -h localhost -t "test/#" -v

# Vérifier les ports
netstat -tuln | grep 1883
```

### Problèmes de base de données

```bash
# Vérifier la connexion InfluxDB
curl http://localhost:8086/ping

# Voir les bases de données
influx -execute "SHOW DATABASES"
```

### Nettoyer et redémarrer complètement

```bash
# Arrêter tous les services
docker-compose down -v

# Nettoyer les données (ATTENTION : perte de données)
rm -rf data/*

# Reconstruire et redémarrer
docker-compose up -d --build
```

## Support

Pour toute question ou problème :
- Ouvrir une issue sur GitHub
- Consulter la documentation dans `/docs`
- Contacter l'équipe de support

## Licence

MIT License - voir le fichier LICENSE pour plus de détails
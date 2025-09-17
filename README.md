# 🐰 RabbitMQ Docker Setup for Koyeb

Configuration Docker de RabbitMQ optimisée pour le déploiement sur Koyeb, conçue pour l'écosystème de microservices Roomee.

## 📋 Vue d'ensemble

Ce repository contient une configuration Docker complète pour déployer RabbitMQ avec l'interface de management sur la plateforme Koyeb. Il inclut la configuration pour le développement local et la production.

## 🛠 Prérequis

- Docker et Docker Compose installés
- Compte Koyeb (pour la production)
- Git configuré

## 🚀 Démarrage rapide

### Développement local

1. **Cloner le repository**
```bash
git clone https://github.com/Roomee-sas/roomee-rabbitmq.git
cd roomee-rabbitmq
```

2. **Configurer les variables d'environnement**
```bash
cp .env.example .env
# Modifier .env avec vos valeurs
```

3. **Démarrer RabbitMQ**
```bash
docker-compose up -d
```

4. **Accéder à l'interface**
- **AMQP**: `localhost:5673`
- **Management UI**: http://localhost:15673
- **Identifiants**: Voir votre fichier `.env`

## 📝 Déploiement sur Koyeb

### 1️⃣ Test local
```bash
# Tester localement
docker-compose up -d

# Vérifier que RabbitMQ fonctionne
curl http://localhost:15672
# Login: roomee_admin / [VOTRE_MOT_DE_PASSE]
```

### 2️⃣ Créer un repository GitHub
```bash
git init
git add .
git commit -m "Initial RabbitMQ setup for Koyeb"
git remote add origin https://github.com/Roomee-sas/roomee-rabbitmq.git
git push -u origin main
```

### 3️⃣ Déploiement sur Koyeb (via Interface Web)

1. **Connectez-vous à Koyeb** : https://app.koyeb.com

2. **Créer une nouvelle App** :
   - Cliquez sur "Create App"
   - Choisissez "GitHub" comme source
   - Sélectionnez votre repository `roomee-rabbitmq`

3. **Configuration du service** :
   ```
   Build settings:
   - Builder: Dockerfile
   - Dockerfile path: ./Dockerfile
   - Build context: .

   Deployment settings:
   - Instance type: Small (minimum recommandé)
   - Regions: Europe (fra) ou selon vos besoins
   - Replicas: 1 (augmenter pour HA)
   ```

4. **Variables d'environnement** :
   ```
   RABBITMQ_DEFAULT_USER=roomee_admin
   RABBITMQ_DEFAULT_PASS=[VOTRE_MOT_DE_PASSE]
   ```

5. **Configuration des ports** :
   ```
   - Port 5672: AMQP (TCP)
   - Port 15672: Management UI (HTTP)
   ```

6. **Health checks** :
   ```
   Path: /api/health
   Port: 15672
   Protocol: HTTP
   ```

### 4️⃣ Déploiement via Koyeb CLI (Alternative)

```bash
# Installation Koyeb CLI
brew install koyeb/tap/koyeb-cli  # macOS
# ou
curl -fsSL https://github.com/koyebinc/koyeb-cli/releases/latest/download/koyeb-linux-amd64 -o koyeb

# Login
koyeb login

# Déployer
koyeb app create roomee-rabbitmq \
  --git https://github.com/Roomee-sas/roomee-rabbitmq.git \
  --git-branch main \
  --docker-file Dockerfile \
  --ports 5672:tcp,15672:http \
  --env RABBITMQ_DEFAULT_USER=roomee_admin \
  --env RABBITMQ_DEFAULT_PASS=[VOTRE_MOT_DE_PASSE] \
  --regions fra \
  --instance-type small
```

### 5️⃣ Configuration post-déploiement

1. **Obtenir l'URL publique** :
   ```
   https://roomee-rabbitmq-roomee.koyeb.app
   ```

2. **Accéder à l'interface Management** :
   ```
   https://roomee-rabbitmq-roomee.koyeb.app:15672
   ```

3. **Configurer les exchanges et queues** :
   ```javascript
   // Dans votre code Node.js
   const amqpUrl = 'amqps://roomee_admin:[VOTRE_MOT_DE_PASSE]@roomee-rabbitmq-roomee.koyeb.app:5672';
   ```

## 🔧 Configuration pour les microservices Roomee

### Mise à jour des services
Mettre à jour les `.env` de chaque service :

```bash
# api-authentication/.env
AMQP_GATEWAY_URL=amqps://roomee_admin:[VOTRE_MOT_DE_PASSE]@roomee-rabbitmq-roomee.koyeb.app:5672
AMQP_EXCHANGE_NAME=roomee_events
AMQP_QUEUE_NAME=auth_queue
AMQP_ROUTING_KEY_BASE=roomee.auth

# api-notification/.env
AMQP_GATEWAY_URL=amqps://roomee_admin:[VOTRE_MOT_DE_PASSE]@roomee-rabbitmq-roomee.koyeb.app:5672
AMQP_EXCHANGE_NAME=roomee_events
AMQP_QUEUE_NAME=notification_queue
AMQP_ROUTING_KEY_BASE=roomee.notification

# api-news/.env
AMQP_GATEWAY_URL=amqps://roomee_admin:[VOTRE_MOT_DE_PASSE]@roomee-rabbitmq-roomee.koyeb.app:5672
AMQP_EXCHANGE_NAME=roomee_events
AMQP_QUEUE_NAME=news_queue
AMQP_ROUTING_KEY_BASE=roomee.news
```

## 🔒 Sécurité

### SSL/TLS
Koyeb fournit automatiquement des certificats SSL. Utilisez `amqps://` au lieu de `amqp://`.

### Firewall Rules
Dans Koyeb, configurez les règles réseau :
- Port 5672 : Autoriser uniquement depuis vos services
- Port 15672 : Restreindre aux IPs administrateurs

### Rotation des mots de passe
```bash
# Se connecter au container
koyeb exec roomee-rabbitmq -- rabbitmqctl change_password roomee_admin NEW_PASSWORD
```

## 📊 Monitoring

### Dashboard Koyeb
- Metrics CPU/Memory
- Logs en temps réel
- Alertes automatiques

### RabbitMQ Management
Accessible via : `https://roomee-rabbitmq-roomee.koyeb.app:15672`
- Queues status
- Message rates
- Connections
- Exchanges

## 🔄 Mise à jour

### Via GitHub (recommandé)
```bash
# Modifier le code
git add .
git commit -m "Update RabbitMQ configuration"
git push origin main
# Koyeb redéploie automatiquement
```

### Via CLI
```bash
koyeb service redeploy roomee-rabbitmq/roomee-rabbitmq
```

## 🔧 Configuration des microservices

Une fois RabbitMQ déployé, configurez vos microservices avec l'URL de connexion :

### Local
```javascript
const amqpUrl = 'amqp://roomee_admin:[PASSWORD]@localhost:5673';
```

### Production (Koyeb)
```javascript
const amqpUrl = 'amqps://roomee_admin:[PASSWORD]@roomee-rabbitmq-roomee.koyeb.app:5672';
```

## 📁 Structure du projet

```
├── Dockerfile              # Configuration Docker
├── docker-compose.yml      # Setup développement local
├── rabbitmq.conf          # Configuration RabbitMQ
├── startup.sh             # Script d'initialisation
├── .env.example           # Template variables d'environnement
├── .gitignore            # Fichiers ignorés par Git
└── README.md             # Ce fichier
```

## 🆘 Troubleshooting

### Connection refused
```bash
# Vérifier le statut du container
docker ps | grep rabbitmq

# Voir les logs
docker logs roomee-rabbitmq
```

### Port déjà utilisé
Modifier les ports dans `docker-compose.yml` :
```yaml
ports:
  - "5674:5672"   # AMQP
  - "15674:15672" # Management UI
```

## 🔒 Sécurité

- ⚠️ **Jamais de mots de passe en clair** dans le code
- 🔐 Variables d'environnement uniquement
- 🛡️ SSL/TLS automatique sur Koyeb
- 🔑 Authentification forte requise

## 📚 Ressources

- [Koyeb Documentation](https://www.koyeb.com/docs)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [RabbitMQ Docker Image](https://hub.docker.com/_/rabbitmq)

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit les changements (`git commit -am 'Ajouter nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Créer une Pull Request

---

**Roomee SAS** - Plateforme hôtelière complète
# 🚀 Guide de Déploiement RabbitMQ sur Koyeb

## Prérequis
- Compte Koyeb actif
- Docker installé localement
- Git configuré
- Koyeb CLI (optionnel)

## 📝 Procédure étape par étape

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

## 🆘 Troubleshooting

### Connection refused
```bash
# Vérifier le statut
koyeb service get roomee-rabbitmq/roomee-rabbitmq

# Voir les logs
koyeb service logs roomee-rabbitmq/roomee-rabbitmq
```

### Memory issues
Augmenter l'instance type dans Koyeb :
```bash
koyeb service update roomee-rabbitmq/roomee-rabbitmq \
  --instance-type medium
```

### Queue overflow
Se connecter et purger :
```bash
koyeb exec roomee-rabbitmq -- rabbitmqctl purge_queue queue_name
```

## 📚 Ressources

- [Koyeb Documentation](https://www.koyeb.com/docs)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [RabbitMQ Docker Image](https://hub.docker.com/_/rabbitmq)

## 💡 Tips

1. **Haute Disponibilité** : Déployez plusieurs replicas
2. **Backup** : Configurez des exports réguliers des définitions
3. **Monitoring** : Intégrez avec Datadog/NewRelic via Koyeb
4. **Scaling** : Utilisez l'autoscaling Koyeb basé sur CPU/Memory

## Coûts estimés sur Koyeb

- **Starter** (Free) : Limité, pour tests
- **Small Instance** : ~$8/mois
- **Medium Instance** : ~$16/mois (recommandé pour production)
- **Large Instance** : ~$32/mois (haute charge)

## 🔗 Connexion rapide pour vos services

Une fois déployé sur Koyeb, utilisez cette URL dans vos services :
```javascript
const amqpUrl = 'amqps://roomee_admin:[VOTRE_MOT_DE_PASSE]@roomee-rabbitmq-roomee.koyeb.app:5672';
```
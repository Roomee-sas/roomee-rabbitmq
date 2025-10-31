# 🐰 RabbitMQ Docker pour Roomee

Configuration Docker de RabbitMQ optimisée pour l'écosystème de microservices Roomee, compatible développement local et production Koyeb.

---

## 📋 Vue d'Ensemble

- **Version** : RabbitMQ 3.13 (Alpine)
- **Exchanges** : `roomee_events` (principal) + `gateway_exchange`
- **Environnements** : Local (Docker) + Production (Koyeb)
- **Documentation** : Configuration réseau, tests et troubleshooting

---

## 🚀 Démarrage Rapide

### Local (Docker)

```bash
# 1. Démarrer RabbitMQ
docker-compose up -d

# 2. Créer l'utilisateur admin (si nécessaire)
docker exec roomee-rabbitmq rabbitmqctl add_user roomee_admin R00m33_@MQP_2024!
docker exec roomee-rabbitmq rabbitmqctl set_user_tags roomee_admin administrator
docker exec roomee-rabbitmq rabbitmqctl set_permissions -p / roomee_admin ".*" ".*" ".*"

# 3. Vérifier
docker ps | grep roomee-rabbitmq
docker logs roomee-rabbitmq
```

### Accès Local

- **AMQP** : `localhost:5673`
- **Management UI** : http://localhost:15673
- **Credentials** : `roomee_admin` / `R00m33_@MQP_2024!`

### Tester

```bash
cd examples
npm install
npm test  # Test complet local
```

---

## 🌐 Configuration Production (Koyeb)

### Informations du Service

D'après Koyeb Overview :

| Type | Adresse | Usage |
|------|---------|-------|
| **Management UI** | `https://amqp.roomee.io/` | Interface web |
| **Private Address** | `roomee-rabbitmq.amqp.internal:5672` | ✅ Services Koyeb |
| **TCP Proxy** | `01.proxy.koyeb.app:22328` | Tests externes |

### URL pour Services Koyeb

```bash
AMQP_GATEWAY_URL=amqp://roomee_admin:R00m33_%40MQP_2024%21@roomee-rabbitmq.amqp.internal:5672
```

**Important** :
- `roomee-rabbitmq` : Nom du service
- `.amqp` : Nom de l'App Koyeb
- `.internal` : Réseau privé Koyeb
- Port `5672` : AMQP standard
- `@` encodé en `%40`, `!` encodé en `%21`

---

## ⚙️ Configuration par Service

### Variables d'Environnement Koyeb

Pour **chaque microservice** sur Koyeb, définir ces variables :

#### api-authentication
```bash
AMQP_GATEWAY_URL=amqp://roomee_admin:R00m33_%40MQP_2024%21@roomee-rabbitmq.amqp.internal:5672
AMQP_EXCHANGE_NAME=roomee_events
AMQP_QUEUE_NAME=amqp_authentication_queue_prod
AMQP_ROUTING_KEYS=["roomee.auth.*"]
AMQP_ROUTING_KEY_BASE=roomee.auth
```

#### api-notification
```bash
AMQP_GATEWAY_URL=amqp://roomee_admin:R00m33_%40MQP_2024%21@roomee-rabbitmq.amqp.internal:5672
AMQP_EXCHANGE_NAME=roomee_events
AMQP_QUEUE_NAME=amqp_notification_queue_prod
AMQP_ROUTING_KEYS=["roomee.notification.*","roomee.auth.*","roomee.member.*"]
AMQP_ROUTING_KEY_BASE=roomee.notification
```

#### api-hotel
```bash
AMQP_GATEWAY_URL=amqp://roomee_admin:R00m33_%40MQP_2024%21@roomee-rabbitmq.amqp.internal:5672
AMQP_EXCHANGE_NAME=roomee_events
AMQP_QUEUE_NAME=amqp_hotel_queue_prod
AMQP_ROUTING_KEYS=["roomee.hotel.*"]
AMQP_ROUTING_KEY_BASE=roomee.hotel
```

#### api-staff-member
```bash
AMQP_GATEWAY_URL=amqp://roomee_admin:R00m33_%40MQP_2024%21@roomee-rabbitmq.amqp.internal:5672
AMQP_EXCHANGE_NAME=roomee_events
AMQP_QUEUE_NAME=amqp_member_queue_prod
AMQP_ROUTING_KEYS=["roomee.member.*","roomee.auth.*"]
AMQP_ROUTING_KEY_BASE=roomee.member
```

#### api-news
```bash
AMQP_GATEWAY_URL=amqp://roomee_admin:R00m33_%40MQP_2024%21@roomee-rabbitmq.amqp.internal:5672
AMQP_EXCHANGE_NAME=roomee_events
AMQP_QUEUE_NAME=amqp_news_queue_prod
AMQP_ROUTING_KEYS=["roomee.news.*","roomee.member.*"]
AMQP_ROUTING_KEY_BASE=roomee.news
```

#### api-media
```bash
AMQP_GATEWAY_URL=amqp://roomee_admin:R00m33_%40MQP_2024%21@roomee-rabbitmq.amqp.internal:5672
AMQP_EXCHANGE_NAME=roomee_events
AMQP_QUEUE_NAME=amqp_media_queue_prod
AMQP_ROUTING_KEYS=["roomee.media.*"]
AMQP_ROUTING_KEY_BASE=roomee.media
```

---

## 📦 Exchanges Configurés

### 1. `roomee_events` (Principal)

- **Type** : Topic
- **Usage** : Exchange principal pour tous les événements
- **Routing Keys** : `roomee.<service>.<action>`
- **Exemples** :
  - `roomee.auth.user.created`
  - `roomee.notification.sent`
  - `roomee.member.updated`

### 2. `gateway_exchange`

- **Type** : Topic
- **Usage** : Communication via gateway
- **Créé automatiquement** au démarrage

---

## 🧪 Tests et Scripts

### Scripts de Test Disponibles

```bash
cd examples
npm install

# Test local complet (Docker)
npm test

# Test Koyeb via Management API
npm run test:koyeb-api

# Test Koyeb via TCP Proxy
npm run test:koyeb-proxy

# Lister les exchanges
./list-exchanges.sh

# Créer un exchange
./create-exchange.sh mon_exchange topic
```

---

## 🔧 Troubleshooting

### Erreur : `ENOTFOUND roomee-rabbitmq`

**Cause** : URL incorrecte pour Koyeb.

**Solution** : Utiliser l'adresse privée complète :
```bash
roomee-rabbitmq.amqp.internal:5672
```

### Erreur : `no exchange 'gateway_exchange'`

**Solution** : L'exchange est maintenant créé automatiquement dans `definitions.json`.

### Port déjà utilisé (local)

**Cause** : RabbitMQ installé localement occupe le port 5672.

**Solution** : Le `docker-compose.yml` utilise déjà le port `5673` pour éviter ce conflit.

### Créer un utilisateur manuellement

```bash
docker exec roomee-rabbitmq rabbitmqctl add_user roomee_admin R00m33_@MQP_2024!
docker exec roomee-rabbitmq rabbitmqctl set_user_tags roomee_admin administrator
docker exec roomee-rabbitmq rabbitmqctl set_permissions -p / roomee_admin ".*" ".*" ".*"
```

⚠️ **Important** : Ne pas mettre de guillemets autour du mot de passe.

### Vérifier les connexions

```bash
# Logs RabbitMQ
docker logs -f roomee-rabbitmq

# Lister les connexions
docker exec roomee-rabbitmq rabbitmqctl list_connections

# Lister les queues
docker exec roomee-rabbitmq rabbitmqctl list_queues

# Status du service
docker exec roomee-rabbitmq rabbitmq-diagnostics -q ping
```

---

## 🏗️ Architecture Réseau Koyeb

### Réseau Privé vs Public

```
┌─────────────── KOYEB PRIVATE NETWORK ───────────────┐
│                                                      │
│  Services → roomee-rabbitmq.amqp.internal:5672      │
│  (Rapide, sécurisé, recommandé)                     │
│                                                      │
└──────────────────────────────────────────────────────┘
                         │
                         ▼
              https://amqp.roomee.io/
           (Management UI accessible)
                         │
                         ▼
         01.proxy.koyeb.app:22328
       (TCP Proxy pour tests externes)
```

### Pourquoi le Port AMQP n'est pas Accessible Publiquement ?

C'est **normal** et **sécurisé**. Le port 5672 (AMQP) n'est accessible que :

✅ **Depuis vos services Koyeb** (réseau privé)
✅ **Via TCP Proxy** (01.proxy.koyeb.app:22328)
✅ **Via Management UI** (https://amqp.roomee.io/)
❌ **Pas directement depuis l'extérieur** (`amqp.roomee.io:5672`)

---

## 📝 Modifications Techniques Effectuées

### 1. `docker-compose.yml`

```yaml
# Ports modifiés (éviter conflits locaux)
ports:
  - '5673:5672'  # AMQP
  - '15673:15672' # Management UI

# SSL désactivé pour dev local
# - '5671:5671' # À réactiver en prod avec certificats
```

### 2. `rabbitmq.conf`

```ini
# SSL commenté (pas de certificats en dev local)
# listeners.ssl.default = 5671
# ssl_options.cacertfile = /etc/rabbitmq/certs/ca.pem
# ...

# CORS configuré pour domaines Roomee
management.cors.allow_origins.1 = https://apis-dev.roomee.io
management.cors.allow_origins.2 = https://apis-staging.roomee.io
management.cors.allow_origins.3 = https://apis-prod.roomee.io
management.cors.allow_origins.4 = https://amqp.roomee.io
```

⚠️ **Production** : Décommenter et configurer SSL avec de vrais certificats.

### 3. `definitions.json`

```json
{
  "exchanges": [
    { "name": "roomee_events", "type": "topic", "durable": true },
    { "name": "gateway_exchange", "type": "topic", "durable": true }
  ]
}
```

Les exchanges sont créés automatiquement au démarrage.

---

## 🔒 Sécurité

### Développement Local

- Port AMQP sur `5673` (non standard)
- SSL désactivé
- Utilisateur : `roomee_admin`
- Pas d'exposition publique

### Production Koyeb

- Réseau privé `.amqp.internal`
- SSL à configurer (avec certificats)
- Management UI via HTTPS
- Isolation réseau entre services

### Bonnes Pratiques

✅ Ne jamais committer les mots de passe en clair
✅ Utiliser des variables d'environnement
✅ Activer SSL en production
✅ Restreindre l'accès Management UI
✅ Utiliser des mots de passe forts
✅ Rotation régulière des credentials

---

## 📊 Monitoring

### Management UI

Accessible sur http://localhost:15673 (local) ou https://amqp.roomee.io/ (Koyeb) :

- État des connexions
- Queues et messages
- Exchanges et bindings
- Statistiques de performance
- Gestion des utilisateurs

### Logs

```bash
# Logs Docker local
docker logs -f roomee-rabbitmq

# Logs Koyeb
Koyeb Dashboard → Service RabbitMQ → Logs
```

### Vérifications

```bash
# Health check
docker exec roomee-rabbitmq rabbitmq-diagnostics -q check_running

# Liste des exchanges
docker exec roomee-rabbitmq rabbitmqctl list_exchanges

# Liste des queues
docker exec roomee-rabbitmq rabbitmqctl list_queues

# Connexions actives
docker exec roomee-rabbitmq rabbitmqctl list_connections

# Statistiques
curl -s -u roomee_admin:R00m33_@MQP_2024! http://localhost:15673/api/overview
```

---

## 📁 Structure du Projet

```
roomee-amqp-docker/amqp-roomee/
├── Dockerfile                    # Image RabbitMQ personnalisée
├── docker-compose.yml           # Orchestration Docker local
├── rabbitmq.conf                # Configuration RabbitMQ
├── definitions.json             # Exchanges prédéfinis
├── fix-perms-and-start.sh       # Script de démarrage
├── .env.example                 # Template variables
├── .gitignore                   # Fichiers ignorés
├── README.md                    # Cette documentation
└── examples/                    # Scripts de test (ignoré par git)
    ├── package.json
    ├── test-complete.js         # Test local complet
    ├── test-koyeb-api.js        # Test Management API
    ├── test-koyeb-proxy.js      # Test TCP Proxy
    ├── test-producer.js         # Producer simple
    ├── test-consumer.js         # Consumer simple
    ├── create-exchange.sh       # Créer un exchange
    ├── list-exchanges.sh        # Lister les exchanges
    ├── TEST-LOCAL.md            # Guide de test détaillé
    ├── EXCHANGES-GUIDE.md       # Guide des exchanges
    └── ...
```

---

## 🎯 Résumé Configuration

### Local (Développement)

| Paramètre | Valeur |
|-----------|--------|
| URL AMQP | `amqp://roomee_admin:R00m33_%40MQP_2024%21@localhost:5673` |
| Management UI | http://localhost:15673 |
| Port AMQP | 5673 |
| Port Management | 15673 |
| SSL | Désactivé |

### Koyeb (Production)

| Paramètre | Valeur |
|-----------|--------|
| URL AMQP | `amqp://roomee_admin:R00m33_%40MQP_2024%21@roomee-rabbitmq.amqp.internal:5672` |
| Management UI | https://amqp.roomee.io/ |
| TCP Proxy | `01.proxy.koyeb.app:22328` |
| Port AMQP | 5672 |
| SSL | À configurer |

---

## 🆘 Support

### Documentation Additionnelle

- `examples/TEST-LOCAL.md` - Guide de test local détaillé
- `examples/EXCHANGES-GUIDE.md` - Gestion avancée des exchanges
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [Koyeb Documentation](https://www.koyeb.com/docs)

### Commandes Utiles

```bash
# Redémarrer RabbitMQ
docker-compose restart

# Reconstruire l'image
docker-compose build --no-cache

# Arrêter et supprimer les volumes
docker-compose down -v

# Voir les logs en temps réel
docker logs -f roomee-rabbitmq

# Exécuter une commande RabbitMQ
docker exec roomee-rabbitmq rabbitmqctl <commande>
```

---

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/amelioration`)
3. Commit les changements (`git commit -am 'Ajout fonctionnalité'`)
4. Push vers la branche (`git push origin feature/amelioration`)
5. Créer une Pull Request

---

**Roomee SAS** - Infrastructure AMQP pour Microservices

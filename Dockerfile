FROM rabbitmq:3.13-management-alpine

# Configuration de base - Les variables seront définies au runtime par Koyeb
ENV RABBITMQ_DEFAULT_USER=roomee_admin
# Le mot de passe sera défini via les variables d'environnement Koyeb
# ENV RABBITMQ_DEFAULT_PASS sera défini au runtime

# Exposer les ports
# 5672: AMQP port
# 15672: Management plugin port
EXPOSE 5672 15672

# Copier les fichiers de configuration
COPY rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
COPY startup.sh /startup.sh

# Rendre le script exécutable
RUN chmod +x /startup.sh

# Health check pour Koyeb
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD rabbitmq-diagnostics -q ping || exit 1

# Utiliser le script de démarrage
CMD ["/startup.sh"]
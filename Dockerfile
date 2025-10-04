FROM rabbitmq:3.13-management-alpine

# Copie de la conf et des définitions
COPY rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
COPY definitions.json /etc/rabbitmq/definitions.json

# Petit wrapper pour corriger les permissions du volume (cookie, data)
COPY fix-perms-and-start.sh /usr/local/bin/fix-perms-and-start.sh
RUN chmod +x /usr/local/bin/fix-perms-and-start.sh

# On conserve l'image officielle et son entrypoint
# On passe par notre wrapper comme CMD (et PAS comme ENTRYPOINT) pour rester compatible
CMD ["/usr/local/bin/fix-perms-and-start.sh"]

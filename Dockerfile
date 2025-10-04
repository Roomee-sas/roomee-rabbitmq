FROM rabbitmq:3.13-management-alpine

# On a besoin des droits root pour corriger le volume et gérer l'init
USER root

COPY rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
COPY definitions.json /etc/rabbitmq/definitions.json
COPY fix-perms-and-start.sh /usr/local/bin/fix-perms-and-start.sh
RUN chmod +x /usr/local/bin/fix-perms-and-start.sh

# Lance notre wrapper (qui démarre RabbitMQ + init user)
CMD ["/usr/local/bin/fix-perms-and-start.sh"]

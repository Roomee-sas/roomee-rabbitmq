FROM rabbitmq:3.13-management-alpine

# Copie de la conf et des définitions
COPY rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
COPY definitions.json /etc/rabbitmq/definitions.json

# L'image 'management' active déjà le plugin et expose 15672/5672.
# Pas besoin d'entrypoint custom, ni de EXPOSE/HEALTHCHECK supplémentaires ici.

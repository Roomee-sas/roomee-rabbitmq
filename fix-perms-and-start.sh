#!/bin/sh
set -e

# Corriger ownership & permissions sur le volume (requises par Erlang/RabbitMQ)
if [ -d /var/lib/rabbitmq ]; then
  chown -R rabbitmq:rabbitmq /var/lib/rabbitmq || true
  if [ -f /var/lib/rabbitmq/.erlang.cookie ]; then
    chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie || true
    chmod 400 /var/lib/rabbitmq/.erlang.cookie || true
  fi
fi

# Lancer RabbitMQ via l'entrypoint officiel
exec docker-entrypoint.sh rabbitmq-server

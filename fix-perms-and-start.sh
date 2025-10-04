#!/bin/sh
set -eu

# 1) Permissions correctes sur le volume (cookie Erlang)
if [ -d /var/lib/rabbitmq ]; then
  chown -R rabbitmq:rabbitmq /var/lib/rabbitmq || true
  if [ -f /var/lib/rabbitmq/.erlang.cookie ]; then
    chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie || true
    chmod 400 /var/lib/rabbitmq/.erlang.cookie || true
  fi
fi

# 2) Démarrer RabbitMQ en arrière-plan
docker-entrypoint.sh rabbitmq-server -detached

# 3) Attendre que le nœud soit prêt
TRIES=60
until rabbitmq-diagnostics -q ping; do
  TRIES=$((TRIES-1)) || true
  [ "$TRIES" -le 0 ] && { echo "RabbitMQ n'a pas démarré à temps"; exit 1; }
  sleep 2
done

# 4) Créer/mettre à jour l'utilisateur à partir des variables d'env (pas stockées dans le repo)
USER_NAME="${RABBITMQ_DEFAULT_USER:-}"
USER_PASS="${RABBITMQ_DEFAULT_PASS:-}"
USER_VHOST="${RABBITMQ_DEFAULT_VHOST:-/}"

if [ -n "$USER_NAME" ] && [ -n "$USER_PASS" ]; then
  # S'assurer que le vhost existe
  if ! rabbitmqctl list_vhosts -q | grep -x "$USER_VHOST" >/dev/null 2>&1; then
    rabbitmqctl add_vhost "$USER_VHOST"
  fi

  # Créer l'utilisateur s'il n'existe pas, sinon mettre à jour son mot de passe
  if rabbitmqctl list_users -q | awk '{print $1}' | grep -x "$USER_NAME" >/dev/null 2>&1; then
    rabbitmqctl change_password "$USER_NAME" "$USER_PASS" || true
  else
    rabbitmqctl add_user "$USER_NAME" "$USER_PASS"
  fi

  rabbitmqctl set_user_tags "$USER_NAME" administrator || true
  rabbitmqctl set_permissions -p "$USER_VHOST" "$USER_NAME" ".*" ".*" ".*" || true
fi

# 5) Arrêt propre sur SIGTERM (Koyeb)
term() { rabbitmqctl stop; exit 0; }
trap term TERM INT

# 6) Rester au premier plan
tail -F /var/log/rabbitmq/*.log & wait $!

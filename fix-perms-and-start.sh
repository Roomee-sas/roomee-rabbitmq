#!/bin/sh
set -eu

# --- 1) Permissions volume (cookie Erlang doit être 400 / owner rabbitmq) ---
if [ -d /var/lib/rabbitmq ]; then
  chown -R rabbitmq:rabbitmq /var/lib/rabbitmq || true
  if [ -f /var/lib/rabbitmq/.erlang.cookie ]; then
    chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie || true
    chmod 400 /var/lib/rabbitmq/.erlang.cookie || true
  fi
fi

# --- 2) Démarrer le serveur en arrière-plan via l'entrypoint officiel ---
docker-entrypoint.sh rabbitmq-server -detached

# --- 3) Attendre que l'app 'rabbit' soit *vraiment* démarrée ---
# (ping ne suffit pas; on attend le démarrage complet)
rabbitmqctl await_startup

# (optionnel) Attendre que le listener Management soit ouvert
# for i in $(seq 1 60); do nc -z 127.0.0.1 15672 && break || sleep 1; done

# --- 4) Init idempotente de l'utilisateur à partir des variables d'env ---
USER_NAME="${RABBITMQ_DEFAULT_USER:-}"
USER_PASS="${RABBITMQ_DEFAULT_PASS:-}"
USER_VHOST="${RABBITMQ_DEFAULT_VHOST:-/}"

if [ -n "$USER_NAME" ] && [ -n "$USER_PASS" ]; then
  # s'assurer que le vhost existe
  rabbitmqctl add_vhost "$USER_VHOST" 2>/dev/null || true

  # créer l'user ou mettre à jour son mot de passe
  if rabbitmqctl list_users -q | awk '{print $1}' | grep -x "$USER_NAME" >/dev/null 2>&1; then
    rabbitmqctl change_password "$USER_NAME" "$USER_PASS" || true
  else
    rabbitmqctl add_user "$USER_NAME" "$USER_PASS"
  fi

  rabbitmqctl set_user_tags "$USER_NAME" administrator || true
  rabbitmqctl set_permissions -p "$USER_VHOST" "$USER_NAME" ".*" ".*" ".*" || true
fi

# --- 5) Shutdown propre sur SIGTERM (Koyeb) ---
term() { rabbitmqctl stop; exit 0; }
trap term TERM INT

# --- 6) Rester en avant-plan (logs) ---
tail -F /var/log/rabbitmq/*.log & wait $!

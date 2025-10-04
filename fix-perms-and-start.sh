#!/bin/sh
set -eu

# --- 1) Permissions volume (cookie Erlang strict) ---
if [ -d /var/lib/rabbitmq ]; then
  chown -R rabbitmq:rabbitmq /var/lib/rabbitmq || true
  if [ -f /var/lib/rabbitmq/.erlang.cookie ]; then
    chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie || true
    chmod 400 /var/lib/rabbitmq/.erlang.cookie || true
  fi
fi

# --- 2) Init user en tâche de fond, sans jamais faire planter le conteneur ---
init_user() {
  USER_NAME="${RABBITMQ_DEFAULT_USER:-}"
  USER_PASS="${RABBITMQ_DEFAULT_PASS:-}"
  USER_VHOST="${RABBITMQ_DEFAULT_VHOST:-/}"

  # si pas d'env -> rien à faire
  [ -n "$USER_NAME" ] && [ -n "$USER_PASS" ] || return 0

  # Attendre que le nœud réponde au ping
  i=180
  until rabbitmq-diagnostics -q ping; do
    sleep 2
    i=$((i-1)) || true
    [ "$i" -le 0 ] && echo "[init] Timeout ping, abandon init (non bloquant)"; return 0
  done

  # Attendre que *l'app* rabbit soit démarrée (et pas juste le nœud)
  i=180
  until rabbitmqctl await_startup >/dev/null 2>&1; do
    sleep 2
    i=$((i-1)) || true
    [ "$i" -le 0 ] && echo "[init] Timeout await_startup, abandon init (non bloquant)"; return 0
  done

  # Créer le vhost s'il n'existe pas
  rabbitmqctl add_vhost "$USER_VHOST" >/dev/null 2>&1 || true

  # Créer l'utilisateur s'il n'existe pas, sinon MAJ mot de passe
  if rabbitmqctl list_users -q | awk '{print $1}' | grep -x "$USER_NAME" >/dev/null 2>&1; then
    rabbitmqctl change_password "$USER_NAME" "$USER_PASS" || true
  else
    rabbitmqctl add_user "$USER_NAME" "$USER_PASS" || true
  fi

  rabbitmqctl set_user_tags "$USER_NAME" administrator || true
  rabbitmqctl set_permissions -p "$USER_VHOST" "$USER_NAME" ".*" ".*" ".*" || true

  echo "[init] User '$USER_NAME' prêt sur vhost '$USER_VHOST'"
}

init_user &

# --- 3) Lancer RabbitMQ au premier plan (PID 1) ---
exec docker-entrypoint.sh rabbitmq-server

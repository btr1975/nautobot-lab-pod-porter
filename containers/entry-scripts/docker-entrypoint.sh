#!/bin/bash
# Runs on every start of the Nautobot Docker container

# Stop when an error occures
set -e

echo "Run custom secrets loader"

# Loop over each environment variable.
while IFS='=' read -r var_name var_value; do
  # Check if the variable's value begins with /run/secrets/
  if [[ "$var_value" == /run/secrets/* ]]; then
    echo "Found variable '$var_name' referencing file '$var_value'"
    if [ -f "$var_value" ]; then
      # Read the file content using input redirection
      new_value=$(< "$var_value")
      # Escape any embedded double quotes in the new value
      escaped=$(printf "%s" "$new_value" | sed 's/"/\\"/g')
      # Set the variable to the new value in the current shell
      eval "$var_name=\"$escaped\""
      echo "Updated '$var_name' with contents from '$var_value'."
    else
      echo "Warning: File '$var_value' for variable '$var_name' not found." >&2
    fi
  fi
done < <(env)

echo "Completed custom secrets loader"
echo "Run nautobot entrypoint"

# Try to connect to the DB
DB_WAIT_TIMEOUT=${DB_WAIT_TIMEOUT-3}
MAX_DB_WAIT_TIME=${MAX_DB_WAIT_TIME-30}
CUR_DB_WAIT_TIME=0

# set NAUTOBOT_DOCKER_SKIP_INIT to NAUTOBOT_DOCKER_SKIP_INIT, defaulting to false:
NAUTOBOT_DOCKER_SKIP_INIT=${NAUTOBOT_DOCKER_SKIP_INIT-false}
# lowercase NAUTOBOT_DOCKER_SKIP_INIT:
NAUTOBOT_DOCKER_SKIP_INIT=$(echo $NAUTOBOT_DOCKER_SKIP_INIT | tr '[:upper:]' '[:lower:]')
if [[ "$NAUTOBOT_DOCKER_SKIP_INIT" == "false" ]]; then
  while ! nautobot-server post_upgrade 2>&1 && [ "${CUR_DB_WAIT_TIME}" -lt "${MAX_DB_WAIT_TIME}" ]; do
    echo "⏳ Waiting on DB... (${CUR_DB_WAIT_TIME}s / ${MAX_DB_WAIT_TIME}s)"
    sleep "${DB_WAIT_TIMEOUT}"
    CUR_DB_WAIT_TIME=$(( CUR_DB_WAIT_TIME + DB_WAIT_TIMEOUT ))
  done
  if [ "${CUR_DB_WAIT_TIME}" -ge "${MAX_DB_WAIT_TIME}" ]; then
    echo "❌ Waited ${MAX_DB_WAIT_TIME}s or more for the DB to become ready."
    exit 1
  fi
fi

# Run a quick healthcheck and bail if something fails, --deploy will warn on potential issues for production
echo "⏳ Running initial systems check..."
nautobot-server check --deploy
RC=$?
if [[ $RC != 0 ]]; then
	echo -e "❌ Nautobot systems check failed!"
	exit $RC
fi

# Create Superuser if required
if [ "$NAUTOBOT_CREATE_SUPERUSER" == "true" ]; then
  if [ -z ${NAUTOBOT_SUPERUSER_NAME+x} ]; then
    NAUTOBOT_SUPERUSER_NAME='admin'
  fi
  if [ -z ${NAUTOBOT_SUPERUSER_EMAIL+x} ]; then
    NAUTOBOT_SUPERUSER_EMAIL='admin@example.com'
  fi
  if [ -f "/run/secrets/superuser_password" ]; then
    NAUTOBOT_SUPERUSER_PASSWORD="$(< /run/secrets/superuser_password)"
  elif [ -z ${NAUTOBOT_SUPERUSER_PASSWORD+x} ]; then
    echo "❌ NAUTOBOT_SUPERUSER_PASSWORD is required to be defined when creating superuser"
    exit 1
  fi
  if [ -f "/run/secrets/superuser_api_token" ]; then
    NAUTOBOT_SUPERUSER_API_TOKEN="$(< /run/secrets/superuser_api_token)"
  elif [ -z ${NAUTOBOT_SUPERUSER_API_TOKEN+x} ]; then
    echo "❌ NAUTOBOT_SUPERUSER_API_TOKEN is required to be defined when creating superuser"
    exit 1
  fi

  nautobot-server shell --interface python << END
from django.contrib.auth import get_user_model
from nautobot.users.models import Token
u = get_user_model().objects.filter(username='${NAUTOBOT_SUPERUSER_NAME}')
if not u:
    u=get_user_model().objects.create_superuser('${NAUTOBOT_SUPERUSER_NAME}', '${NAUTOBOT_SUPERUSER_EMAIL}', '${NAUTOBOT_SUPERUSER_PASSWORD}')
    Token.objects.create(user=u, key='${NAUTOBOT_SUPERUSER_API_TOKEN}')
else:
    u = u[0]
    if u.email != '${NAUTOBOT_SUPERUSER_EMAIL}':
        u.email = '${NAUTOBOT_SUPERUSER_EMAIL}'
    if not u.check_password('${NAUTOBOT_SUPERUSER_PASSWORD}'):
        u.set_password('${NAUTOBOT_SUPERUSER_PASSWORD}')
    u.save()
    t = Token.objects.filter(user=u)
    if t:
        t = t[0]
        if t.key != '${NAUTOBOT_SUPERUSER_API_TOKEN}':
            t.key = '${NAUTOBOT_SUPERUSER_API_TOKEN}'
            t.save()
END

  echo "💡 Superuser Username: ${NAUTOBOT_SUPERUSER_NAME}, E-Mail: ${NAUTOBOT_SUPERUSER_EMAIL}"
fi

if [ "$NAUTOBOT_UWSGI_PROCESSES" ]; then
  sed -i "s@.*processes = .*\$@processes = $NAUTOBOT_UWSGI_PROCESSES@" /opt/nautobot/uwsgi.ini
fi

if [ "$NAUTOBOT_UWSGI_LISTEN" ]; then
  sed -i "s@.*listen = .*\$@listen = $NAUTOBOT_UWSGI_LISTEN@" /opt/nautobot/uwsgi.ini
fi

if [ "$NAUTOBOT_UWSGI_BUFFER_SIZE" ]; then
  sed -i "s@.*buffer-size = .*\$@buffer-size = $NAUTOBOT_UWSGI_BUFFER_SIZE@" /opt/nautobot/uwsgi.ini
fi

# Launch whatever is passed by docker
# (i.e. the RUN instruction in the Dockerfile)
exec "$@"

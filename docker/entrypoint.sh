#! /usr/bin/env bash

DJANGO_ADMIN=$HOME/venv/bin/django-admin

# Configure settings module
export DJANGO_SETTINGS_MODULE="$1"

# If the DJANGO_LOGGING_SLACK_WEBHOOK environment variable is set, install the
# cedadev-slack-logging-handler package
if [ -n "$DJANGO_LOGGING_SLACK_WEBHOOK" ]; then
  $HOME/venv/bin/pip install https://github.com/cedadev/slack-logging-handler.git || exit 1
fi

# Run database migrations
echo "[INFO] Running database migrations"
$DJANGO_ADMIN migrate --no-input > /dev/null || exit 1

# Create Django superuser if required
if [ "${DJANGO_CREATE_SUPERUSER:-0}" -eq 1 ]; then
  echo "[INFO] Ensuring Django superuser exists"
  # We require that username and email exist
  if [ -z "$DJANGO_SUPERUSER_USERNAME" ]; then
    echo "[ERROR]   DJANGO_SUPERUSER_USERNAME must be set to create superuser"
    exit 1
  fi
  if [ -z "$DJANGO_SUPERUSER_EMAIL" ]; then
    echo "[ERROR]   DJANGO_SUPERUSER_EMAIL must be set to create superuser"
    exit 1
  fi
  # Run a command that has a non-zero exit code if the user already exists
  $DJANGO_ADMIN shell -c "
import sys
from django.contrib.auth import get_user_model

if get_user_model().objects.filter(username='$DJANGO_SUPERUSER_USERNAME').exists():
    sys.exit(1)
" || exit 1
  # A zero exit status means the user needs to be created
  if [ "$?" -eq 0 ]; then
    echo "[INFO] Creating Django superuser"
    # Create the superuser with an unusable password
    $DJANGO_ADMIN createsuperuser --no-input  \
                                  --username "$DJANGO_SUPERUSER_USERNAME"  \
                                  --email "$DJANGO_SUPERUSER_EMAIL"  \
                                  $DJANGO_SUPERUSER_EXTRA_ARGS || exit 1
    # Update the password for the superuser if required
    if [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
      echo "[INFO] Setting Django superuser password"
      $DJANGO_ADMIN shell -c "
from django.contrib.auth import get_user_model

user = get_user_model().objects.get(username='$DJANGO_SUPERUSER_USERNAME')
user.set_password('$DJANGO_SUPERUSER_PASSWORD')
user.save()
" || exit 1
    fi
  fi
fi

# Collect static files for serving later
echo "[INFO] Collecting static files"
$DJANGO_ADMIN collectstatic --no-input --clear > /dev/null || exit 1

# Create the Paste config file
echo "[INFO] Generating Paste config file"
# Note that we have to do this rather than using Paste variables because we want
# to have a dynamic route name in the urlmap
function django_setting {
    $DJANGO_ADMIN shell -c "from django.conf import settings; print(settings.$1)" || exit 1
}
cat > /home/gunicorn/conf/paste.ini <<EOF
[composite:main]
use = egg:Paste#urlmap
/ = django
$(django_setting STATIC_URL) = static

[app:django]
use = call:django_paste:app_factory
django_wsgi_application = $(django_setting WSGI_APPLICATION)

[app:static]
use = egg:Paste#static
document_root = $(django_setting STATIC_ROOT)

[server:main]
use = egg:gunicorn#main
EOF

# Run the app with gunicorn
echo "[INFO] Starting gunicorn"
exec $HOME/venv/bin/gunicorn --config /home/gunicorn/conf/config.py  \
                             --paste /home/gunicorn/conf/paste.ini

#! /usr/bin/env bash

set -ex

DJANGO_ADMIN=$HOME/venv/bin/django-admin

DJANGO_PROJECT_NAME=$1

# Configure settings module
export DJANGO_SETTINGS_MODULE="$DJANGO_PROJECT_NAME.settings"

# Run database migrations
$DJANGO_ADMIN migrate --no-input

# If required, create Django superuser if required
if [ "$DJANGO_CREATE_SUPERUSER" -eq 1 ]; then
  # Run a command that has a non-zero exit code if the user already exists
  $DJANGO_ADMIN shell -c "
import sys
from django.contrib.auth import get_user_model

if get_user_model().objects.filter(username='$DJANGO_SUPERUSER_USERNAME').exists():
    sys.exit(1)
"
  # A zero exit status means the user needs to be created
  if [ "$?" -eq 0 ]; then
    # Create the superuser with an unusable password
    $DJANGO_ADMIN createsuperuser --no-input  \
                                  --username "$DJANGO_SUPERUSER_USERNAME"  \
                                  $DJANGO_SUPERUSER_EXTRA_ARGS
    # Update the password for the superuser
    $DJANGO_ADMIN shell -c "
from django.contrib.auth import get_user_model

user = get_user_model().objects.get(username='$DJANGO_SUPERUSER_USERNAME')
user.set_password('$DJANGO_SUPERUSER_PASSWORD')
user.save()
"
  fi
fi

# Collect static files for serving later
$DJANGO_ADMIN collectstatic --no-input --clear

# Run the app with gunicorn
exec $HOME/venv/bin/gunicorn --config /home/gunicorn/conf/config.py "${DJANGO_PROJECT_NAME}.wsgi"

"""
This module defines some default Django settings using environment variables.
These settings can then serve as a base for the settings file for a Django project.

The settings are intended to be secure by default.
"""

import os


# Security settings
if int(os.environ.get('DJANGO_DEBUG', '0')):
    DEBUG = True
else:
    DEBUG = False
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SECURE_BROWSER_XSS_FILTER = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    if int(os.environ.get('DJANGO_CSRF_COOKIE_HTTPONLY', '0')):
        CSRF_COOKIE_HTTPONLY = True
    X_FRAME_OPTIONS = 'DENY'
    ALLOWED_HOSTS = os.environ['DJANGO_ALLOWED_HOSTS'].split(',')


# Secret key
SECRET_KEY = os.environ['DJANGO_SECRET_KEY']


# Logging settings
if not DEBUG:
    LOG_FORMAT = '[%(levelname)s] [%(asctime)s] [%(name)s:%(lineno)s] [%(threadName)s] %(message)s'
    LOGGING_CONFIG = None
    LOGGING = {
        'version' : 1,
        'disable_existing_loggers' : False,
        'formatters' : {
            'generic' : {
                'format' : LOG_FORMAT,
            },
            'slack' : {
                'format' : '`' + LOG_FORMAT + '`',
            },
        },
        'handlers' : {
            'stdout' : {
                'class' : 'logging.StreamHandler',
                'formatter' : 'generic',
            },
        },
        'loggers' : {
            '' : {
                'handlers' : ['stdout'],
                'level' : 'INFO',
                'propogate' : True,
            },
        },
    }
    if 'DJANGO_LOGGING_SLACK_WEBHOOK' in os.environ:
        LOGGING['handlers']['slack'] = {
            'class' : 'slack_logging_handler.SlackHandler',
            'formatter' : 'slack',
            'level' : 'ERROR',
            'webhook_url' : os.environ['DJANGO_LOGGING_SLACK_WEBHOOK'],
        }
        LOGGING['loggers']['']['handlers'].append('slack')
    import logging.config
    logging.config.dictConfig(LOGGING)


# Database settings
# Any environment variable that starts with DJANGO_DATABASE is interpreted as a
# database URL
# Settings for the default database are taken from either DJANGO_DATABASE or
# DJANGO_DATABASE_DEFAULT
# Settings for named databases are taken from DJANGO_DATABASE_<DBNAME>, i.e.
# DJANGO_DATABASE_USERDB would set the 'userdb' key in DATABASES
import dj_database_url
DATABASES = {
    (k[15:].lstrip('_').lower() or 'default'): dj_database_url.parse(v, con_max_age = 600)
    for k, v in os.environ
    if k.startswith('DJANGO_DATABASE')
}
# If no default database was provided, use an SQLite db in $HOME
if 'default' not in DATABASES:
    DATABASES['default'] = {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(os.environ['HOME'], 'db.sqlite3'),
    }


# Static files settings
STATIC_ROOT = os.path.join(os.environ['HOME'], 'static')

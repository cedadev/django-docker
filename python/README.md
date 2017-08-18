# django-docker Python package

The `django-docker` Python package is designed to help with configuring a Django
application using environment variables.

It focuses on configuring settings that may change with each container instance -
primarily debug mode, security, databases and the secret key. Settings that are
fixed for a given application, such as the installed apps and middleware, are
left to the application to configure.

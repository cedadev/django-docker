# Docker images

This Docker configuration is used to build the
[cedadev/django-docker](https://hub.docker.com/r/cedadev/django-docker/)
images on Docker Hub.

These images can be used as a base for other images for running Django applications
using Docker.

When running your Django application using Docker, it is advisable to ensure that
your containers can be fully configured using environment variables. The
[django-docker Python package](../python) can be used to help with this.


## Building an image for a Docker application

For each tag in the repository, there are two variants: `<tag>` and `<tag>-onbuild`.

The `onbuild` versions include
[ONBUILD triggers](https://docs.docker.com/engine/reference/builder/#onbuild)
that:

1. Copy the contents of the directory containing the inheriting `Dockerfile` into
the image
2. Install the packages from `requirements.txt` using `pip install --no-deps`
3. Install the application itself using `pip install --no-deps -e`

This means that for a simple application, creating a `Dockerfile` to run that
application as a container is as simple as:

```Dockerfile
FROM cedadev/django-docker:<tag>-onbuild

# This is the Python module name of the Django settings to use
CMD ["my_django_application.settings"]
```

When using the plain `<tag>` versions, the inheriting `Dockerfile` is responsible
for installing the application to run:

```Dockerfile
FROM cedadev/django-docker:<tag>

# Install application dependencies
USER root
RUN apt-get update && apt-get install some packages
# Install the application from the current working directory
# NOTE: We have to install as root in order to chown to gunicorn
#       https://github.com/moby/moby/issues/6119
COPY . /home/gunicorn/application
RUN chown -R gunicorn:gunicorn /home/gunicorn/application
# IMPORTANT: If you change to root, remember to change back to the gunicorn user!!!!
USER gunicorn

RUN /home/gunicorn/venv/bin/pip install  \
      --no-deps -r /home/gunicorn/application/requirements.txt
RUN /home/gunicorn/venv/bin/pip install --no-deps -e /home/gunicorn/application

# This is the Python module name of the Django settings to use
CMD ["my_django_application.settings"]
```


## Running a Docker-ised Django application

Once a Docker image exists for your application, you can run it as follows:

```bash
docker run -p 8000:8000 <image>:<tag>
```

Depending how your application is configured, this may not run straight away as
some environment variables may be required to configure the container. Environment
variables can be passed to the Docker container using `-e ENV_VAR=value`.

The following environment variables, if present, are used to configure how Django
is started:

| Variable | Notes |
| --- | --- |
| `DJANGO_CREATE_SUPERUSER` | Set this to `1` to create the specified superuser if they do not already exist. |
| `DJANGO_SUPERUSER_USERNAME` | Required if `DJANGO_CREATE_SUPERUSER=1`. The username for the superuser. |
| `DJANGO_SUPERUSER_EMAIL` | Required if `DJANGO_CREATE_SUPERUSER=1`. The email for the superuser. |
| `DJANGO_SUPERUSER_EXTRA_ARGS` | Extra arguments for the `django-admin createsuperuser` command. |
| `DJANGO_SUPERUSER_PASSWORD` | The password for the password. If not given, no password is set. |


## Building the base images

To build the images, just run the following commands:

```bash
IMAGE=cedadev/django-docker
TAG=$(git describe --always)
docker build -t ${IMAGE}:${TAG} .
docker build -f Dockerfile.onbuild -t ${IMAGE}:${TAG}-onbuild --build-arg FROM_TAG=${TAG} .

# Optionally tag as latest
docker tag ${IMAGE}:${TAG} ${IMAGE}:latest
docker tag ${IMAGE}:${TAG}-onbuild ${IMAGE}:latest-onbuild

# Optionally push to Docker Hub
docker push ${IMAGE}:${TAG}
docker push ${IMAGE}:${TAG}-onbuild
docker push ${IMAGE}:latest
docker push ${IMAGE}:latest-onbuild
```

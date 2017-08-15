# Docker images

This Docker configuration is used to build the
[cedadev/django-docker](https://hub.docker.com/r/cedadev/django-docker/)
images on Docker Hub.

These images can be used as a base for other images for running Django applications
using Docker.

For each tag in the repository, there are two variants: `<tag>` and `<tag>-onbuild`.

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

The `onbuild` version includes
[ONBUILD instructions](https://docs.docker.com/engine/reference/builder/#onbuild)
that:

1. Copy the contents of the directory containing the inheriting `Dockerfile` into
the image
2. Install the packages from `requirements.txt` using `pip install --no-deps`

This means that for a simple application, creating a `Dockerfile` to run that
application as a container is as simple as:

```Dockerfile
FROM cedadev/django-docker:<tag>-onbuild

# This is the Python module name of the Django settings to use
CMD ["my_django_application.settings"]
```


## Building the images

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

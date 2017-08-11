# docker-gunicorn

This repository is used to build the
[cedadev/docker-gunicorn](https://hub.docker.com/r/cedadev/docker-gunicorn/)
images on Docker Hub.

These images can be used as a base for other images for running Python WSGI applications.

For each tag in the repository, there are two variants: `<tag>` and `<tag>-onbuild`.

When using the plain `<tag>` versions, the inheriting `Dockerfile` is responsible
for installing the application to run:

```Dockerfile
FROM cedadev/docker-gunicorn:<tag>

# Install application dependencies
USER root
RUN apt-get update && apt-get install some packages
# IMPORTANT: If you change to root to install system packages, remember to change
#            back to the gunicorn user!!!!
USER gunicorn

COPY ./src /application
RUN pip install /application

# This is the path to the WSGI application object to be run by gunicorn
CMD ["python.path.to.wsgi:app"]
```

The `onbuild` version includes
[ONBUILD instructions](https://docs.docker.com/engine/reference/builder/#onbuild)
that copy the contents of the directory containing the inheriting `Dockerfile` into
the image and `pip install` them. This means that for a simple application, creating
a `Dockerfile` to run that application as a container is as simple as:

```Dockerfile
FROM cedadev/docker-gunicorn:<tag>-onbuild

# This is the path to the WSGI application object to be run by gunicorn
CMD ["python.path.to.wsgi:app"]
```


## Building the images

To build the images, just run the following commands:

```bash
IMAGE=cedadev/docker-gunicorn
TAG=$(git describe --always)
docker build -t ${IMAGE}:${TAG} .
docker build -f Dockerfile.onbuild -t ${IMAGE}:${TAG}-onbuild --build-arg FROM_TAG=${TAG} .

# Optionally push to Docker Hub
docker push ${IMAGE}:${TAG}
docker push ${IMAGE}:${TAG}-onbuild
```

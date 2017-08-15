FROM python:3.6-slim

# Ensure that Python outputs everything that's printed inside
# the application rather than buffering it.
ENV PYTHONUNBUFFERED 1

# Install git so that we can pip install directly from git repos
# Install jq to help with Django setup
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Create the gunicorn user
RUN groupadd gunicorn &&  \
    useradd -g gunicorn -m -d /home/gunicorn -s /sbin/nologin gunicorn

# Everything from now on should be done as gunicorn
USER gunicorn

# Create a virtualenv for gunicorn owned by the gunicorn user
RUN python3 -m venv /home/gunicorn/venv

# Install gunicorn
RUN /home/gunicorn/venv/bin/pip install gunicorn

# Install gunicorn config file
COPY gunicorn-config.py /home/gunicorn/conf/config.py

# Install startup script
COPY entrypoint.sh /entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]

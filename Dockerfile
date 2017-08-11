FROM python:3.6-slim

# Ensure that Python outputs everything that's printed inside
# the application rather than buffering it.
ENV PYTHONUNBUFFERED 1

# Create the gunicorn user
RUN groupadd gunicorn &&  \
    useradd -g gunicorn -m -d /home/gunicorn -s /sbin/nologin gunicorn

# Everything from now on should be done as gunicorn
USER gunicorn

# Create a virtualenv for gunicorn owned by the gunicorn user
RUN python3 -m venv /home/gunicorn/venv

# Install gunicorn
RUN /home/gunicorn/venv/bin/pip install gunicorn

# Install gunicorn config files
COPY config.py /home/gunicorn/conf/config.py

EXPOSE 8000

ENTRYPOINT ["/home/gunicorn/venv/bin/gunicorn", "--config", "/home/gunicorn/conf/config.py"]

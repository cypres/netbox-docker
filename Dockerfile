FROM python:3-alpine
LABEL maintainer=hans.duedal@visma.com

RUN apk add --no-cache graphviz postgresql-dev libffi-dev build-base libxml2-dev libxslt-dev jpeg-dev

ENV NETBOX_RELEASE v2.2.2
ADD "https://api.github.com/repos/digitalocean/netbox/tarball/$NETBOX_RELEASE" /usr/src/app/release.tar.gz

WORKDIR /usr/src/app
RUN tar -xvzpf release.tar.gz \
    && mv digitalocean-netbox-* digitalocean-netbox \
    && pip install -r digitalocean-netbox/requirements.txt \
    && pip install gunicorn

# Basic config that will allow container to run
# Should be replaced by a kubernetes configmap to /usr/src/app/config/
RUN mkdir config \
    && cp digitalocean-netbox/netbox/netbox/configuration.example.py config/netbox.py \
    && ln -s /usr/src/app/config/netbox.py digitalocean-netbox/netbox/netbox/configuration.py \
    && sed -i --  "s/SECRET_KEY = ''/SECRET_KEY = '($(/usr/src/app/digitalocean-netbox/netbox/generate_secret_key.py)'/g" \
    config/netbox.py \
    && sed -i --  "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['0.0.0.0'\]/g" \
    config/netbox.py

ENTRYPOINT ["gunicorn", "-w 3", "-u nobody", "-b 0.0.0.0:8001", "--pythonpath /usr/src/app/digitalocean-netbox/netbox", "netbox.wsgi"]
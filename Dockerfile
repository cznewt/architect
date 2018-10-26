### Build and install packages
FROM python:3.6 as build-python

RUN \
    apt-get -y update && \
    apt-get install -y gettext && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install pipenv
ADD Pipfile /app/
ADD Pipfile.lock /app/
WORKDIR /app
RUN pipenv install --system --deploy --dev

### Build static assets
FROM node:10 as build-nodejs

ADD package.json /app/
WORKDIR /app
RUN npm install

### Final image
FROM python:3.6-slim

ARG STATIC_URL
ENV STATIC_URL ${STATIC_URL:-/static/}

RUN \
    apt-get update && \
    apt-get install -y libyaml-dev libssl1.1 python3-dev python3-pip libxml2-dev libxslt1-dev libffi-dev graphviz libpq-dev libssl-dev libffi-dev shared-mime-info mime-support rubygems ruby-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    gem install sass --no-user-install

ADD architect/ /app/architect/
ADD manage.py entrypoint.sh /app/
COPY --from=build-python /usr/local/lib/python3.6/site-packages/ /usr/local/lib/python3.6/site-packages/
COPY --from=build-python /usr/local/bin/ /usr/local/bin/
COPY --from=build-nodejs /app/node_modules /app/node_modules
WORKDIR /app

RUN SECRET_KEY=dummy \
    STATIC_URL=${STATIC_URL} \
    python3 manage.py collectstatic --no-input && \
    python3 manage.py compress

RUN useradd --system architect && \
    mkdir -p /app/media /app/static && \
    chmod 777 /app/entrypoint.sh && \
    chown -R architect:architect /app/

USER architect

#EXPOSE 8181
#ENV PORT 8181

ENV PYTHONUNBUFFERED 1
ENV PROCESSES 4

#CMD ["uwsgi", "/app/architect/wsgi/uwsgi.ini"]
CMD ["/app/entrypoint.sh"]

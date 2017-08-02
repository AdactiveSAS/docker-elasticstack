FROM ubuntu:16.04
MAINTAINER Lucas Pantanella

# Skip "apt-get install" interactive prompts during build
ARG DEBIAN_FRONTEND=noninteractive
# Disable setting kernel parameters
ARG ES_SKIP_SET_KERNEL_PARAMETERS=true

ARG ELASTIC_S3_BACKUP_REGION
ARG ELASTIC_S3_BACKUP_BUCKET
ARG ELASTIC_S3_BACKUP_SECRET_KEY
ARG ELASTIC_S3_BACKUP_ACCESS_KEY

ADD backup/backup.js /var/lib/elasticsearch-backup/backup.js
ADD backup/elasticsearch_backup.cron /etc/cron.d/elasticsearch_backup

RUN \
# Base install
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y wget curl httpie vim nano screen apt-utils apt-transport-https openjdk-8-jdk nodejs cron && \
# Add the Elastic key & repositories
  wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
  echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee -a /etc/apt/sources.list.d/elasticsearch-5.x.list && \
  apt-get update && \
# Install Elasticsearch
  apt-get install -y elasticsearch && \
# Install Kibana
  apt-get install -y kibana && \
# Install Logstash
  apt-get install -y logstash && \
# Install S3 Repository Plugin
  /usr/share/elasticsearch/bin/elasticsearch-plugin install -b repository-s3 && \
# Allow network access to Elasticsearch from the host
  sed -i "s/#network.host:.*/network.host: 0.0.0.0/" /etc/elasticsearch/elasticsearch.yml && \
  sed -i "s/#server.host:.*/server.host: 0.0.0.0/" /etc/kibana/kibana.yml

RUN \
# Set the repository-s3 configuration
  chmod 0644 /etc/cron.d/elasticsearch_backup && \
  chown -R elasticsearch:elasticsearch /var/lib/elasticsearch && \
  service elasticsearch restart && \
  sleep 10 && \
  curl -XPUT 'localhost:9200/_snapshot/s3_backup?pretty' -H 'Content-Type: application/json' \
  -d'{"type": "s3","settings": {"bucket": "'${ELASTIC_S3_BACKUP_BUCKET}'","region": "'${ELASTIC_S3_BACKUP_REGION}'", "protocol": "https", "secret_key": "'${ELASTIC_S3_BACKUP_SECRET_KEY}'", "access_key": "'${ELASTIC_S3_BACKUP_ACCESS_KEY}'"}}' && \
  service elasticsearch stop

EXPOSE \
  # Elasticsearch RESTful API / Java API
  9200 9300 \
  # Kibana
  5601 \
  # Logstash
  5044

CMD \
  service cron start && \
  chown -R elasticsearch:elasticsearch /var/lib/elasticsearch && \
  service elasticsearch start && \
  service kibana start && \
  nohup /usr/share/logstash/bin/logstash --path.settings /etc/logstash -f /etc/logstash/conf.d/logstash.conf > /var/log/logstash/logstash_run.log 2>&1 & \
  /bin/bash

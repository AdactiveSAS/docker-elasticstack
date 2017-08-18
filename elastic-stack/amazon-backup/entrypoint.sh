#!/bin/bash

chown -R elasticsearch:elasticsearch /var/log
chown -R elasticsearch:elasticsearch /var/lib/elasticsearch

# Make sure dependencies are installed
apt-get install -y curl nodejs cron

# restore rights on cron
chmod 0644 /etc/cron.d/elastic_db_backup

if [ ! "$(ls -A /etc/elasticsearch/repository-s3)" ]; then
    echo "Installing repository-s3 \n"

    if [ ! -z "${PROXY_HOST}" ]; then
        echo "No proxy";
    else
        echo "Using proxy ${PROXY_HOST}";
        export ES_JAVA_OPTS="$ES_JAVA_OPTS -DproxyHost=${PROXY_HOST} -DproxyPort=${PROXY_PORT}";
    fi

    # install repository-s3 plugin
    /usr/share/elasticsearch/bin/elasticsearch-plugin install -b repository-s3

    service elasticsearch start

    # Wait for elasticsearch to be started
    sleep 10

    # create the Elastic repository-s3 configuration
    curl -XPUT 'http://localhost:9200/_snapshot/s3_backup?pretty' -H 'Content-Type: application/json' -d'{"type": "s3","settings": {"bucket": "'${ELASTIC_S3_BACKUP_BUCKET}'","region": "'${ELASTIC_S3_BACKUP_REGION}'", "protocol": "https", "secret_key": "'${ELASTIC_S3_BACKUP_SECRET_KEY}'", "access_key": "'${ELASTIC_S3_BACKUP_ACCESS_KEY}'"}}'
else
    service elasticsearch start
fi

service cron start
service kibana start
nohup /usr/share/logstash/bin/logstash --path.settings /etc/logstash -f /etc/logstash/conf.d/logstash.conf > /var/log/logstash/logstash_run.log 2>&1 &

/bin/bash
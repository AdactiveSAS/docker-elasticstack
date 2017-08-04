#!/bin/bash

ELASTIC_S3_BACKUP_REGION="your-s3-region"
ELASTIC_S3_BACKUP_BUCKET="your-s3-bucket"
ELASTIC_S3_BACKUP_SECRET_KEY="your-s3-secret"
ELASTIC_S3_BACKUP_ACCESS_KEY="your-s3-key"

chown -R elasticsearch:elasticsearch /var/log
chown -R elasticsearch:elasticsearch /var/lib/elasticsearch

# re/install repository-s3 plugin
/usr/share/elasticsearch/bin/elasticsearch-plugin install -b repository-s3
# restore rights on cron
chmod 0644 /etc/cron.d/elastic_db_backup

if [ ! "$(ls -A /var/lib/elasticsearch)" ]; then
    # install dependencies
    apt-get install -y curl nodejs cron
    # create the Elastic repository-s3 configuration
    service elasticsearch start
    sleep 10
    curl -XPUT 'http://localhost:9200/_snapshot/s3_backup?pretty' -H 'Content-Type: application/json' -d'{"type": "s3","settings": {"bucket": "'${ELASTIC_S3_BACKUP_BUCKET}'","region": "'${ELASTIC_S3_BACKUP_REGION}'", "protocol": "https", "secret_key": "'${ELASTIC_S3_BACKUP_SECRET_KEY}'", "access_key": "'${ELASTIC_S3_BACKUP_ACCESS_KEY}'"}}'
else
    service elasticsearch start
fi

service kibana start
nohup /usr/share/logstash/bin/logstash --path.settings /etc/logstash -f /etc/logstash/conf.d/logstash.conf > /var/log/logstash/logstash_run.log 2>&1 &

/bin/bash
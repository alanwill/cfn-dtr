#!/bin/bash

# Install Postgres Client
echo deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
  apt-key add -
apt-get update
apt-get install postgresql-client-9.4 -y

# The IP address for postgres is assigned on boot and isn't always the same,
# this looks it up and sets the env variable
apt-get install jq -y
export PG_HOST=`docker inspect docker_trusted_registry_postgres | jq '.[] | .NetworkSettings.IPAddress' | sed -e 's/^"//'  -e 's/"$//'`

# Look up the latest backup available on S3
export PG_LATESTBACKUP=`aws s3 ls s3://$DTRS3BUCKET/backup/ | awk '{print substr($0, index($0, $4))}' | grep pg | sort -n | tail -1`

# Download the latest backup
aws s3 cp s3://$DTRS3BUCKET/backup/$PG_LATESTBACKUP /root

# Restore backup
pg_restore -h $PG_HOST \
-p 5432 \
-U postgres \
-c \
-d postgres \
/root/$PG_LATESTBACKUP

# Clean up the archive file
rm -f /root/$PG_LATESTBACKUP

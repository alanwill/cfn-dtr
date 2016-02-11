#!/bin/bash

# The IP address for postgres is assigned on boot and isn't always the same,
# this looks it up and sets the env variable
apt-get install jq -y
export PG_HOST=`docker inspect docker_trusted_registry_postgres | jq '.[] | .NetworkSettings.IPAddress' | sed -e 's/^"//'  -e 's/"$//'`

# Create a script that will backup the db, copy the archive to S3, then cleanup.
# This script will be called by cron
sudo -H -u ubuntu bash -c cat <<EOF >> /root/pgbackup.sh
#!/bin/bash
pg_dump -h $PG_HOST \
-p 5432 \
-U postgres \
--format=t \
-f pg-backup-\`date +%s\`.bck \
postgres
/usr/local/bin/aws s3 cp . s3://$DTRS3BUCKET/backup/ --recursive --exclude "*" --include "*.bck"
rm -f *.bck
EOF

chmod 755 /root/pgbackup.sh

# Create cron schedule to run every 15 minutes.
crontab -l > pgbackup
echo "*/15 * * * * /root/pgbackup.sh"  \>/root/pgbackupcron.log 2\>\&1 >> pgbackup
crontab pgbackup
rm pgbackup

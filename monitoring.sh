#!/bin/bash

apt-get update -y
apt-get install unzip -y
apt-get install libwww-perl libdatetime-perl libswitch-perl -y

cd /root
aws s3 cp s3://$DTRS3BUCKET/install/CloudWatchMonitoringScripts-1.2.1.zip /root
unzip /root/CloudWatchMonitoringScripts-1.2.1.zip
rm /root/CloudWatchMonitoringScripts-1.2.1.zip

# Create cron schedule to run every 5 minutes.
crontab -l > cloudwatch-mon
echo "*/5 * * * * /root/aws-scripts-mon/mon-put-instance-data.pl --mem-util --swap-util --disk-space-util --disk-path=/ --auto-scaling --from-cron" >> cloudwatch-mon
crontab cloudwatch-mon
rm cloudwatch-mon

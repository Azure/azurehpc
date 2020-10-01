#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GRAFANA_SERVER=$1
GRAFANA_USER=$2
GRAFANA_PWD=$3
TELEGRAF_CONF=$4

if [ -z "$GRAFANA_SERVER" ]; then
    echo "Grafana server parameter is required"
    exit 1
fi
if [ -z "$GRAFANA_USER" ]; then
    echo "Grafana user parameter is required"
    exit 1
fi
if [ -z "$GRAFANA_PWD" ]; then
    echo "Grafana password parameter is required"
    exit 1
fi
if [ -z "$TELEGRAF_CONF" ]; then
    echo "Telegraf configuration file parameter is required"
    exit 1
fi

echo "#### Configuration repo for InfluxDB:"
cat <<EOF | tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/centos/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

echo "#### Telegraf Installation:"
yum -y install telegraf

# Update telegraph.conf
TELEGRAF_CONF_DIR=/etc/telegraf
cp $TELEGRAF_CONF_DIR/telegraf.conf $TELEGRAF_CONF_DIR/telegraf.conf.origin
cp $DIR/$TELEGRAF_CONF $TELEGRAF_CONF_DIR/telegraf.conf

sed -i "s#__GRAFANA_SERVER__#$GRAFANA_SERVER#" $TELEGRAF_CONF_DIR/telegraf.conf
sed -i "s#__GRAFANA_USER__#$GRAFANA_USER#" $TELEGRAF_CONF_DIR/telegraf.conf
sed -i "s#__GRAFANA_PWD__#$GRAFANA_PWD#" $TELEGRAF_CONF_DIR/telegraf.conf

echo "#### Starting Telegraf services:"
systemctl daemon-reload
systemctl start telegraf
systemctl enable telegraf

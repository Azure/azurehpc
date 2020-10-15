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
if [ -z "$TELEGRAF_CONF" ]; then
    echo "Using embedded configuration file"
cat << EOF > $TELEGRAF_CONF_DIR/telegraf.conf
[global_tags]
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  hostname = ""
  omit_hostname = false
[[outputs.influxdb]]
  urls = ["http://$GRAFANA_SERVER:8086"]
  database = "monitor"
  username = "$GRAFANA_USER"
  password = "$GRAFANA_PWD"
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
[[inputs.interrupts]]
  cpu_as_tag = false
[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]
[[inputs.diskio]]
[[inputs.kernel]]
[[inputs.mem]]
[[inputs.processes]]
[[inputs.swap]]
[[inputs.system]]
[[inputs.net]]
[[inputs.conntrack]]
  files = ["ip_conntrack_count","ip_conntrack_max","nf_conntrack_count","nf_conntrack_max"]
EOF

else
    echo "Using $TELEGRAF_CONF"
    cp $DIR/$TELEGRAF_CONF $TELEGRAF_CONF_DIR/telegraf.conf
    sed -i "s#__GRAFANA_SERVER__#$GRAFANA_SERVER#" $TELEGRAF_CONF_DIR/telegraf.conf
    sed -i "s#__GRAFANA_USER__#$GRAFANA_USER#" $TELEGRAF_CONF_DIR/telegraf.conf
    sed -i "s#__GRAFANA_PWD__#$GRAFANA_PWD#" $TELEGRAF_CONF_DIR/telegraf.conf
fi

# Inject global tags like the VM Size and the VMSS Name if any
compute=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01" | jq '.')
AZHPC_VMSIZE=$(echo $compute | jq -r '.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}
sed -i "s/#vmsize =/vmsize = \"$AZHPC_VMSIZE\"/" $TELEGRAF_CONF_DIR/telegraf.conf

vmssName=$(echo $compute | jq -r '.vmScaleSetName')
if [ "$vmssName" != "" ]; then
    sed -i "s/#vmss =/vmss = \"$vmssName\"/" $TELEGRAF_CONF_DIR/telegraf.conf
fi

echo "#### Starting Telegraf services:"
systemctl start telegraf
systemctl enable telegraf

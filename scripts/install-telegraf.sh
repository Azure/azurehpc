#!/bin/bash
GRAFANA_SERVER=$1
GRAFANA_USER=$2
GRAFANA_PWD=$3

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

echo "Push right config .... "
# Update telegraph.conf
cp /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.origin

cat << EOF > /etc/telegraf/telegraf.conf
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

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

[[inputs.diskio]]
[[inputs.kernel]]
[[inputs.mem]]
[[inputs.processes]]
[[inputs.swap]]
[[inputs.system]]
[[inputs.net]]
EOF

echo "#### Starting Telegraf services:"
systemctl daemon-reload
systemctl start telegraf
systemctl enable telegraf

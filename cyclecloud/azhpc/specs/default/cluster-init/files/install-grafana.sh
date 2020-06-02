#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GRAFANA_USER=${1-azhpc}
GRAFANA_PWD=$2

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

echo "#### Configuration repo for Grafana:"
cat <<EOF | tee /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

echo "#### InfluxDB Installation:"
yum -y install influxdb
echo "#### Grafana Installation:"
yum -y install grafana


echo "#### Starting InfluxDB services:"
systemctl daemon-reload
systemctl start influxdb
systemctl enable influxdb
echo "#### Starting Grafana services:"
systemctl start grafana-server
systemctl enable grafana-server

#echo "#### Opening InfluxDB firewalld port 80(83|86):"
#sudo firewall-cmd --permanent --zone=public --add-port=8086/tcp
#sudo firewall-cmd --permanent --zone=public --add-port=8083/tcp
#echo "#### Opening Grafana firewalld port 3000:"
#sudo firewall-cmd --permanent --zone=public --add-port=3000/tcp
#echo "#### Reload firewall rules:"
#sudo firewall-cmd --reload


echo "#### Configuration of influxDB User and DB:"
curl "http://localhost:8086/query" --data-urlencode "q=CREATE USER admindb WITH PASSWORD '$GRAFANA_PWD' WITH ALL PRIVILEGES"
curl "http://localhost:8086/query" --data-urlencode "q=CREATE USER $GRAFANA_USER WITH PASSWORD '$GRAFANA_PWD'"
curl "http://localhost:8086/query" --data-urlencode "q=CREATE DATABASE monitor"
curl "http://localhost:8086/query" --data-urlencode "q=GRANT ALL ON monitor to $GRAFANA_USER"

echo "Add the administrator"
# https://grafana.com/docs/grafana/latest/administration/cli/
grafana-cli admin reset-admin-password "$GRAFANA_PWD"

echo "Create the datasource"
# https://grafana.com/docs/grafana/latest/administration/provisioning/
grafana_etc_root=/etc/grafana/provisioning
dashboard_dir=/var/lib/grafana/dashboards
cat <<EOF > $grafana_etc_root/datasources/azhpc.yml
apiVersion: 1

datasources:
  - name: azhpc
    type: influxdb
    access: proxy
    database: monitor
    user: $GRAFANA_USER
    password: "$GRAFANA_PWD"
    url: http://localhost:8086
    jsonData:
      httpMode: GET
EOF
chown root:grafana $grafana_etc_root/datasources/azhpc.yml

cat <<EOF > $grafana_etc_root/dashboards/azhpc.yml
apiVersion: 1

providers:
- name: 'azhpc'
  orgId: 1
  folder: ''
  folderUid: ''
  type: file
  disableDeletion: false
  editable: true
  allowUiUpdates: true
  options:
    path: $dashboard_dir
EOF

chown root:grafana $grafana_etc_root/dashboards/azhpc.yml

mkdir $dashboard_dir
chown grafana:grafana $dashboard_dir

cp $DIR/telegraf_dashboard.json $dashboard_dir

echo "Start grafana-server"
systemctl stop grafana-server
systemctl start grafana-server

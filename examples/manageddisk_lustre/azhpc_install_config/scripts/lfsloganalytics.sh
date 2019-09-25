#!/bin/bash

# arg: $1 = name
# arg: $2 = log analytics workspace id
# arg: $3 = log analytics key

name=$1
log_analytics_workspace_id=$2
log_analytics_key=$3

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sed "s#__FS_NAME__#${name}#g;s#__LOG_ANALYTICS_WORKSPACE_ID__#${log_analytics_workspace_id}#g;s#__LOG_ANALYTICS_KEY__#${log_analytics_key}#g"  $DIR/lfsloganalyticsd.sh.in >/usr/bin/lfsloganalyticsd.sh

chmod +x /usr/bin/lfsloganalyticsd.sh

cat <<EOF >/lib/systemd/system/lfsloganalytics.service
[Unit]
Description=Lustre logging service to Log Analytics.

[Service]
Type=simple
ExecStart=/bin/bash /usr/bin/lfsloganalyticsd.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable lfsloganalytics
systemctl start lfsloganalytics
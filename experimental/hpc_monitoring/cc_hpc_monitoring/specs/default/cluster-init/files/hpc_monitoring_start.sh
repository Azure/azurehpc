#!/bin/bash

cat <<EOF >/lib/systemd/system/hpc_monitoring.service
[Unit]
Description=HPC/AI Cluster Monitoring logging service to Log Analytics.

[Service]
Type=simple
ExecStart=/bin/bash /opt/hpc_monitoring/hpc_data_collector.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable hpc_monitoring
systemctl start hpc_monitoring

#!/bin/bash

cat <<EOF >/lib/systemd/system/gpu_monitoring.service
[Unit]
Description=GPU Monitoring logging service to Log Analytics.

[Service]
Type=simple
ExecStart=/bin/bash /opt/gpu_monitoring/gpu_data_collector.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable gpu_monitoring
systemctl start gpu_monitoring

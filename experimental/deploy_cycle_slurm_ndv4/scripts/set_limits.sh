#!/bin/bash

cp /etc/security/limits.conf /tmp/
cat << EOF >> /tmp/limits.conf
* hard memlock unlimited
* soft memlock unlimited
* hard nofile 65535
* soft nofile 65535
EOF
sudo cp /tmp/limits.conf /etc/security/limits.conf
rm /tmp/limits.conf

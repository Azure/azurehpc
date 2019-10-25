#!/bin/bash

# arg: $1 = lfsserver
# arg: $2 = storage account
# arg: $3 = storage key
# arg: $4 = storage container
master=$1
storage_account=$2
storage_key=$3
storage_container=$4

# adding kernel module for lustre client
yum install -y kmod-lustre-client
weak-modules --add-kernel $(uname -r)

yum install -y \
    https://github.com/whamcloud/lemur/releases/download/0.5.2/lhsm-0.5.2-1.x86_64.rpm \
    https://github.com/whamcloud/lemur/releases/download/0.5.2/lemur-data-movers-0.5.2-1.x86_64.rpm \
    https://github.com/whamcloud/lemur/releases/download/0.5.2/lemur-hsm-agent-0.5.2-1.x86_64.rpm \
    https://github.com/whamcloud/lemur/releases/download/0.5.2/lemur-testing-0.5.2-1.x86_64.rpm

wget https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.12.1.linux-amd64.tar.gz
export PATH=/usr/local/go/bin:$PATH

yum install -y git gcc
go get -u github.com/edwardsp/lemur/cmd/lhsm-plugin-az
go build github.com/edwardsp/lemur/cmd/lhsm-plugin-az
cp lhsm-plugin-az /usr/libexec/lhsmd

mkdir -p /var/run/lhsmd
chmod 755 /var/run/lhsmd

mkdir -p /etc/lhsmd
chmod 755 /etc/lhsmd

cat <<EOF >/etc/lhsmd/agent
mount_root="/mnt/lustre"

# Lustre NID and filesystem name for the front end filesystem, the agent will mount this
client_device="${master}@tcp:/LustreFS"

# Do you want to use S3 and POSIX, in this example we use POSIX
enabled_plugins=["lhsm-plugin-az"]

## Directory to look for the plugins
plugin_dir="/usr/libexec/lhsmd"

# TBD, I used 16
handler_count=16

# TBD
snapshots {
        enabled = false
}
EOF
chmod 600 /etc/lhsmd/agent

cat <<EOF >/etc/lhsmd/lhsm-plugin-az
region = "westeurope"
az_storage_account = "$storage_account"
az_storage_key = "$storage_key"

num_threads = 32

#
# One or more archive definition is required.
#
archive  "az-blob" {
    id = 1                           # Must be unique to this endpoint
    container = "$storage_container" # Container used for this archive
    prefix = ""                   # Optional prefix
    num_threads = 32
}
EOF
chmod 600 /etc/lhsmd/lhsm-plugin-az

cat <<EOF >/etc/systemd/system/lhsmd.service
[Unit]
Description=The lhsmd server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=simple
PIDFile=/run/lhsmd.pid
ExecStartPre=/bin/mkdir -p /var/run/lhsmd
ExecStart=/sbin/lhsmd -config /etc/lhsmd/agent
Restart=always

[Install]
WantedBy=multi-user.target
EOF
chmod 600 /etc/systemd/system/lhsmd.service

systemctl daemon-reload
systemctl enable lhsmd
systemctl start lhsmd

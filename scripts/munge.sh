#!/bin/bash

MUNGEKEY=$1

yum install -y epel-release
yum install munge munge-libs munge-devel -y

echo ${MUNGEKEY} > /etc/munge/munge.key
chown munge /etc/munge/munge.key
chmod 600 /etc/munge/munge.key
systemctl enable munge
systemctl start munge


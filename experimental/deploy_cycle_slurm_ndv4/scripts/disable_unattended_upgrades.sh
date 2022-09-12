#!/bin/bash
sed -i '/distro_id/s/^\/*/\/\//' /etc/apt/apt.conf.d/50unattended-upgrades

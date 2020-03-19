#!/bin/bash

# set to permissive for now (until reboot)
setenforce 0
# prep to have selinux disabled after reboot
sed -i 's/SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config

#!/bin/bash

setenforce 0
sed -i 's/SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config

#!/bin/bash

yum -y install epel-release
yum -y install git jq htop

# change access to resource so that temp jobs can be written there
chmod 777 /mnt/resource


#!/bin/bash
SHARED_APPS=/share/apps

cd $SHARED_APPS
yum install -y git
git clone https://github.com/Azure/azurehpc.git

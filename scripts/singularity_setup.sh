#!/bin/bash

acr_repo=$1
acr_pass=$2

yum --releasever=7.6.1810 -y install singularity

wget https://github.com/deislabs/oras/releases/download/v0.7.0/oras_0.7.0_linux_amd64.tar.gz -O - | tar -C /usr/local/bin -zxvf - oras

cat <<EOF >>/etc/bashrc
export SINGULARITY_DOCKER_USERNAME=$acr_repo
export SINGULARITY_DOCKER_PASSWORD="$acr_pass"
EOF

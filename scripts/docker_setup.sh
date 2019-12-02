#!/bin/bash

acr_repo=$1
acr_pass=$2
USER=$3

RELEASE=$(cat /etc/redhat-release | cut -d' ' -f4)

yum --releasever=$RELEASE -y install docker pssh

groupadd docker
usermod -aG docker $USER

systemctl enable docker
systemctl start docker

cat <<EOF >/etc/profile.d/azhpc_docker.sh
export DOCKER_USERNAME=$acr_repo
export DOCKER_PASSWORD="$acr_pass"
EOF

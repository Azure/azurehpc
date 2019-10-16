#!/bin/bash
acr_repo=$1
acr_pass=$2

RELEASE=$(cat /etc/redhat-release | cut -d' ' -f4)
echo $RELEASE

yum --releasever=$RELEASE -y install singularity

wget -q https://github.com/deislabs/oras/releases/download/v0.7.0/oras_0.7.0_linux_amd64.tar.gz -O - | tar -C /usr/local/bin -zxvf - oras


cat <<EOF >>/etc/profile.d/azhpc_singularity.sh
export SINGULARITY_DOCKER_USERNAME=$acr_repo
export SINGULARITY_DOCKER_PASSWORD="$acr_pass"
export SINGULARITY_CACHEDIR=/mnt/resource
export SINGULARITY_TMPDIR=/mnt/resource
EOF

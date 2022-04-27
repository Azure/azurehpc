#!/bin/bash
  
USER=<USER>

apt-get remove -y docker docker-engine docker.io containerd runc
rm -rf /var/lib/docker
apt-get autoclean
apt-get update

apt install -y  apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update
apt-cache policy docker-ce
apt install -y docker-ce

usermod -aG docker $USER

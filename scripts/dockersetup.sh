#!/bin/bash

# Install docker
yum --releasever=7.6.1810 -y install docker

# Set up so user can run without sudo
sudo groupadd docker
sudo usermod -aG docker $USER

# Start up docker
sudo systemctl start docker

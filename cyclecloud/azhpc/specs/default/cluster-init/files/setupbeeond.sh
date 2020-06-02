#!/bin/bash

# this script needs to run without sudo
#  - the keys from the user are used for the root user

sudo wget -O /etc/yum.repos.d/beegfs-rhel7.repo https://www.beegfs.io/release/beegfs_7_1/dists/beegfs-rhel7.repo
sudo rpm --import https://www.beegfs.io/release/latest-stable/gpg/RPM-GPG-KEY-beegfs

sudo yum install -y epel-release
sudo yum install -y psmisc libbeegfs-ib beeond pdsh

sudo sed -i 's/^buildArgs=-j8/buildArgs=-j8 BEEGFS_OPENTK_IBVERBS=1 OFED_INCLUDE_PATH=\/usr\/src\/ofa_kernel\/default\/include/g' /etc/beegfs/beegfs-client-autobuild.conf

sudo /etc/init.d/beegfs-client rebuild

sudo cp -r $HOME/.ssh /root/.

sudo mkdir /mnt/resource/beeond
sudo chmod 777 /mnt/resource/beeond
sudo mkdir /beeond
sudo chmod 777 /beeond

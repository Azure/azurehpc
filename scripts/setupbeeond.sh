#!/bin/bash
MOUNT_ROOT=${1:-/mnt/resource}
# this script needs to run without sudo
#  - the keys from the user are used for the root user

sudo wget -O /etc/yum.repos.d/beegfs-rhel7.repo https://www.beegfs.io/release/beegfs_7.2/dists/beegfs-rhel7.repo
sudo rpm --import https://www.beegfs.io/release/latest-stable/gpg/RPM-GPG-KEY-beegfs

sudo yum install -y epel-release
sudo yum install -y psmisc libbeegfs-ib beeond pdsh

sudo sed -i 's/^buildArgs=-j8/buildArgs=-j8 BEEGFS_OPENTK_IBVERBS=1 OFED_INCLUDE_PATH=\/usr\/src\/ofa_kernel\/default\/include/g' /etc/beegfs/beegfs-client-autobuild.conf

# ibverbs API changed, small patch, specify a Reason for rdma_reject: unsupported, till handled in Beegfs upstream
sudo sed -i  's/rdma_reject(cm_id, NULL, 0)/rdma_reject(cm_id, NULL, 0, 5)/g' /opt/beegfs/src/client/client_module_7/source/common/net/sock/ibv/IBVSocket.c

sudo /etc/init.d/beegfs-client rebuild || exit 1

sudo cp -r $HOME/.ssh /root/.

sudo mkdir $MOUNT_ROOT/beeond
sudo chmod 777 $MOUNT_ROOT/beeond
sudo mkdir /beeond
sudo chmod 777 /beeond

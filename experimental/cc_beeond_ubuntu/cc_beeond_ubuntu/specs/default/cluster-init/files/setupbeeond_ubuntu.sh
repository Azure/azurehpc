#!/bin/bash

MOUNT_ROOT=${1:-/mnt/resource_nvme}
MOUNTPOINT=${2:-/beeond}

wget -q https://www.beegfs.io/release/latest-stable/gpg/DEB-GPG-KEY-beegfs -O- | sudo apt-key add -
wget -q https://www.beegfs.io/release/beegfs_7.2.5/dists/beegfs-deb9.list -O- | sudo tee /etc/apt/sources.list.d/beegfs-deb9.list &>/dev/null

apt-get update -q
apt-get install -y libbeegfs-ib beeond pdsh

sed -i 's/^buildArgs=-j8/buildArgs=-j8 BEEGFS_OPENTK_IBVERBS=1 OFED_INCLUDE_PATH=\/usr\/src\/ofa_kernel\/default\/include/g' /etc/beegfs/beegfs-client-autobuild.conf

/etc/init.d/beegfs-client rebuild || exit 1
modprobe beegfs || exit 1

chmod 777 /mnt
mkdir $MOUNT_ROOT/beeond
chmod 777 $MOUNT_ROOT/beeond
mkdir $MOUNTPOINT
chmod 777 $MOUNTPOINT

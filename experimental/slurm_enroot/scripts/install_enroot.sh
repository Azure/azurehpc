#!/bin/bash

set -x

arch=$(uname -m)
yum install -y epel-release
rpm -q enroot || yum install -y https://github.com/NVIDIA/enroot/releases/download/v3.3.0/enroot-3.3.0-1.el7.${arch}.rpm
rpm -q enroot+caps || yum install -y https://github.com/NVIDIA/enroot/releases/download/v3.3.0/enroot+caps-3.3.0-1.el7.${arch}.rpm

#TODO: separate install (all nodes) and configure (compute)

#sysctl -w user.max_user_namespaces=1417997
grep user.max_user_namespaces /etc/sysctl.conf || echo 'user.max_user_namespaces = 1417997' >> /etc/sysctl.conf
grep namespace.unpriv_enable /etc/default/grub || sed -i.bak 's/\(GRUB_CMDLINE_LINUX.*\)"$/\1 namespace.unpriv_enable=1 user_namespace.enable=1 vsyscall=emulate"/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Use local temporary disk for enroot
cat <<"EOF" > /etc/enroot/enroot.conf
ENROOT_RUNTIME_PATH /run/enroot/user-$(id -u)
ENROOT_CACHE_PATH /mnt/resource/enroot-cache/user-$(id -u)
ENROOT_DATA_PATH /mnt/resource/enroot-data/user-$(id -u)
ENROOT_TEMP_PATH /mnt/resource/enroot-temp
ENROOT_SQUASH_OPTIONS -noI -noD -noF -noX -no-duplicates
ENROOT_MOUNT_HOME n
ENROOT_RESTRICT_DEV y
ENROOT_ROOTFS_WRITABLE y
EOF

# Install extra hooks for PMIx
cp -fv /usr/share/enroot/hooks.d/50-slurm-pmi.sh /usr/share/enroot/hooks.d/50-slurm-pytorch.sh /etc/enroot/hooks.d

# Install NVIDIA container support
# DIST=$(. /etc/os-release; echo $ID$VERSION_ID)
# curl -s -L https://nvidia.github.io/libnvidia-container/$DIST/libnvidia-container.repo | \
#   tee /etc/yum.repos.d/libnvidia-container.repo

# yum -y makecache
# yum install -y libnvidia-container-tools


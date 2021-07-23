#!/bin/bash

set -x

arch=$(uname -m)
yum install -y epel-release
rpm -q enroot || yum install -y https://github.com/NVIDIA/enroot/releases/download/v3.3.0/enroot-3.3.0-1.el7.${arch}.rpm
rpm -q enroot+caps || yum install -y https://github.com/NVIDIA/enroot/releases/download/v3.3.0/enroot+caps-3.3.0-1.el7.${arch}.rpm

#sysctl -w user.max_user_namespaces=1417997
grep user.max_user_namespaces /etc/sysctl.conf || echo 'user.max_user_namespaces = 1417997' >> /etc/sysctl.conf
grep namespace.unpriv_enable /etc/default/grub || sed -i.bak 's/\(GRUB_CMDLINE_LINUX.*\)"$/\1 namespace.unpriv_enable=1 user_namespace.enable=1 vsyscall=emulate"/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Use local disk for enroot
echo 'ENROOT_RUNTIME_PATH /run/enroot/user-$(id -u)' >> /etc/enroot/enroot.conf
echo 'ENROOT_CACHE_PATH /mnt/resource/enroot-cache/user-$(id -u)' >> /etc/enroot/enroot.conf
echo 'ENROOT_DATA_PATH /mnt/resource/enroot-data/user-$(id -u)' >> /etc/enroot/enroot.conf
echo 'ENROOT_TEMP_PATH /mnt/resource/enroot-temp' >> /etc/enroot/enroot.conf
#TODO: fix the permissions - change mode=777 to owner=slurm once pyxis is set up
# move it to the SLURM prolog
echo "mkdir -p /run/enroot /mnt/resource/{enroot-cache,enroot-data,enroot-temp}
chmod 777 /run/enroot /mnt/resource/{enroot-cache,enroot-data,enroot-temp}
" >> /etc/rc.local
chmod +x  /etc/rc.local
systemctl enable rc-local


# Install NVIDIA container support
# DIST=$(. /etc/os-release; echo $ID$VERSION_ID)
# curl -s -L https://nvidia.github.io/libnvidia-container/$DIST/libnvidia-container.repo | \
#   tee /etc/yum.repos.d/libnvidia-container.repo

# yum -y makecache
# yum install -y libnvidia-container-tools


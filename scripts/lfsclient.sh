#!/bin/bash

# arg: $1 = lfsserver
# arg: $2 = mount point (default: /lustre)
master=$1
lfs_mount=${2:-/lustre}


if rpm -q lustre; then

    # if the server packages are installed only the client kmod is needed
    # for 2.10 and nothing extra is needed for 2.12
    if [ "$lustre_version" = "2.10" ]; then

        if ! rpm -q lustre-client-dkms; then
            yum -y install lustre-client-dkms || exit 1
        fi

    fi

else

    # install the client RPMs if not already installed
    if ! rpm -q lustre-client lustre-client-dkms; then
        yum -y install lustre-client lustre-client-dkms || exit 1
    fi
    weak-modules --add-kernel $(uname -r)

fi

mkdir $lfs_mount
echo "${master}@tcp0:/LustreFS $lfs_mount lustre flock,defaults,_netdev 0 0" >> /etc/fstab
mount -a
chmod 777 $lfs_mount

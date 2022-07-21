#!/bin/bash

# Make sure /mnt/resource is mounted
mount | grep resource || mount /mnt/resource

## Enroot support
# Exit if enroot is not in the image
[ -d /etc/enroot ] || exit 0

mkdir -pv /run/enroot /mnt/resource/{enroot-cache,enroot-data,enroot-temp}
chmod -v 777 /run/enroot /mnt/resource/{enroot-cache,enroot-data,enroot-temp}

ENROOT_CONF=/etc/enroot/enroot.conf
egrep '^ENROOT_RUNTIME_PATH' ${ENROOT_CONF} || echo 'ENROOT_RUNTIME_PATH /run/enroot/user-$(id -u)' >> ${ENROOT_CONF}
egrep '^ENROOT_CACHE_PATH' ${ENROOT_CONF} || echo 'ENROOT_CACHE_PATH /mnt/resource/enroot-cache/user-$(id -u)' >> ${ENROOT_CONF}
egrep '^ENROOT_DATA_PATH' ${ENROOT_CONF} || echo 'ENROOT_DATA_PATH /mnt/resource/enroot-data/user-$(id -u)' >> ${ENROOT_CONF}
egrep '^ENROOT_TEMP_PATH' ${ENROOT_CONF} || echo 'ENROOT_TEMP_PATH /mnt/resource/enroot-temp' >> ${ENROOT_CONF}
egrep '^ENROOT_SQUASH_OPTIONS' ${ENROOT_CONF} || echo 'ENROOT_SQUASH_OPTIONS -noI -noD -noF -noX -no-duplicates' >> ${ENROOT_CONF}
egrep '^ENROOT_MOUNT_HOME' ${ENROOT_CONF} || echo 'ENROOT_MOUNT_HOME n' >> ${ENROOT_CONF}
egrep '^ENROOT_RESTRICT_DEV' ${ENROOT_CONF} || echo 'ENROOT_RESTRICT_DEV y' >> ${ENROOT_CONF}
egrep '^ENROOT_ROOTFS_WRITABLE' ${ENROOT_CONF} || echo 'ENROOT_ROOTFS_WRITABLE y' >> ${ENROOT_CONF}
egrep '^MELLANOX_VISIBLE_DEVICES' ${ENROOT_CONF} || echo 'MELLANOX_VISIBLE_DEVICES all' >> ${ENROOT_CONF}

# Exit if no NVIDIA devices detected
[ -c /dev/nvidia0 ] || exit 0

# Verify that NVIDIA UVM driver is running and device file is present
# https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#runfile-verifications
# If not, CUDA inside the container will fail
if [ ! -c /dev/nvidia-uvm ]; then
    echo "ERROR: NVIDIA UVM driver is not running. Starting..."
    /sbin/modprobe nvidia-uvm
    if [ "$?" -eq 0 ]; then
        # Find out the major device number used by the nvidia-uvm driver
        D=`grep nvidia-uvm /proc/devices | awk '{print $1}'`
        mknod -m 666 /dev/nvidia-uvm c $D 0
        echo "Started NVIDIA UVM driver."
    else
        echo "ERROR: NVIDIA UVM driver could not be started."
        exit 1
    fi
fi


exit 0

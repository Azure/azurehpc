#!/bin/bash
#set -o pipefail
set -x

PYXIS_VERSION=${1:-0.11.0}

wget https://github.com/NVIDIA/pyxis/archive/refs/tags/v${PYXIS_VERSION}.tar.gz
tar xzf v${PYXIS_VERSION}.tar.gz
cd pyxis-${PYXIS_VERSION}/

make install

cp -fv /usr/local/lib/slurm/spank_pyxis.so /apps/slurm/
cp -fv /usr/local/lib/slurm/spank_pyxis.so /usr/lib64/slurm/
chmod +x /usr/lib64/slurm/spank_pyxis.so

mkdir -pv /apps/slurm/plugstack.conf.d /apps/slurm/scripts

echo 'include /etc/slurm/plugstack.conf.d/*' > /apps/slurm/plugstack.conf
echo 'required /usr/lib64/slurm/spank_pyxis.so' > /apps/slurm/plugstack.conf.d/pyxis.conf

# ln -sv /apps/slurm/plugstack.conf /etc/slurm/plugstack.conf
# ln -sv /apps/slurm/plugstack.conf.d /etc/slurm/plugstack.conf.d

cat <<"EOF" > /apps/slurm/scripts/prolog.sh
#!/bin/bash

#TODO: fix the permissions - change mode=777 to owner=slurm once pyxis is set up
# Example: https://github.com/NVIDIA/deepops/blob/20.08/roles/slurm/templates/etc/slurm/prolog.d/50-all-enroot-dirs

mkdir -pv /run/enroot /mnt/resource/{enroot-cache,enroot-data,enroot-temp}
chmod -v 777 /run/enroot /mnt/resource/{enroot-cache,enroot-data,enroot-temp}

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
        exit 1
    fi
fi

exit 0
EOF

chmod +x /apps/slurm/scripts/prolog.sh

cat <<EOF >> /apps/slurm/slurm.conf
Prolog=/apps/slurm/scripts/prolog.sh
PrologFlags=Alloc
EOF

systemctl restart slurmctld
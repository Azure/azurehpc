#!/bin/bash

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

if ! is_slurm_controller; then
while [ ! -f /etc/sysconfig/slurmd ]
do
sleep 2
done
grep -q PMIX_MCA /etc/sysconfig/slurmd
pmix_is_not_set=$?
if [ $pmix_is_not_set ]; then
# slurmd environment variables for PMIx
cat <<EOF >> /etc/sysconfig/slurmd

PMIX_MCA_ptl=^usock
PMIX_MCA_psec=none
PMIX_SYSTEM_TMPDIR=/var/empty
PMIX_MCA_gds=hash
HWLOC_COMPONENTS=-opencl
EOF
systemctl restart slurmd
fi
fi

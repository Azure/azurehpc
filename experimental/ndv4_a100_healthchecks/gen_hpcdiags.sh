#!/bin/bash

#Run pre-installed hpc diagnostics and deposit the compressed tar file in OUTDIR
#
# takes one argument, the slurm hostname.

USER=cormac
OUTDIR=/shared/home/${USER}/hpcdiags
CLUSTER=cluster_name

sudo chmod 775 /opt/azurehpc/diagnostics/gather_azhpc_vm_diagnostics.sh

sudo rm /opt/azurehpc/diagnostics/*.tar.gz

sudo /opt/azurehpc/diagnostics/gather_azhpc_vm_diagnostics.sh << EOF
n
y
EOF

hpcdiag_path=$(ls /opt/azurehpc/diagnostics/*.tar.gz)
hpcdiag_file=$(basename $hpcdiag_path)
cp /opt/azurehpc/diagnostics/*.tar.gz $OUTDIR/${CLUSTER}-$1-$hpcdiag_file

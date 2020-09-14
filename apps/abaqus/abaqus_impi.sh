#!/bin/bash
APPLICATION='ABAQUS'
CORES=`cat $PBS_NODEFILE | wc -l`
PPN=`cat $PBS_NODEFILE | uniq -c | head -1 | awk '{ print $1 }'`
hostlist=`cat $PBS_NODEFILE | sort -u | awk -vORS=, '{ print $1 }' | sed 's/,$/\n/'`   

DATA_DIR=${DATA_DIR:-/data}
MODEL=${MODEL:-e1}
SHARED_APPS=/apps
export mpi_options="-env IMPI_FABRICS=shm:ofa -env I_MPI_FALLBACK_DEVICE=0"

#define hosts in abaqus_v6.env file
# mp_file_system=(LOCAL,LOCAL)
# verbose=3
#license_server_type=FLEXNET
#abaquslm_license_file="27000@${LICENSE_SERVER}"
cat <<EOF >abaqus_v6.env
mp_host_list=[['$(sed "s/,/',$PPN],['/g" <<< $hostlist)',$PPN]]
mp_host_split=8
scratch="$PBS_O_WORKDIR"
mp_mpirun_options="$mpi_options"
EOF

# need to unset CCP_NODES otherwise Abaqus think it is running on HPC Pack
unset CCP_NODES

source /etc/profile
module use /usr/share/Modules/modulefiles
module load mpi/impi
source $MPI_BIN/mpivars.sh

ABAQUS="$SHARED_APPS/SIMULIA/EstProducts/2020/linux_a64/code/bin/SMALauncher"
JOBNAME=$MODEL-$CORES

$ABAQUS -j $JOBNAME -input "${DATA_DIR}/$MODEL.inp" -cpus $CORES -interactive 

#!/bin/bash
CORES=`cat $PBS_NODEFILE | wc -l`
PPN=`cat $PBS_NODEFILE | uniq -c | head -1 | awk '{ print $1 }'`
hostlist=`cat $PBS_NODEFILE | sort -u | awk -vORS=, '{ print $1 }' | sed 's/,$/\n/'`   

#NOTE!!!! Update the below details before running the script
ABAQUS_BENCHMARK_STORAGEENDPOINT="<benchmark storage endpoint>"
ABAQUS_BENCHMARK_SASKEY="<saskey>"
LICENSE_SERVER="<license server ip>"

echo "----- get Abaqus test case $MODEL -----"
wget -q "${ABAQUS_BENCHMARK_STORAGEENDPOINT}/abaqus-benchmarks/${MODEL}.inp?${ABAQUS_BENCHMARK_SASKEY}" -O ${MODEL}.inp

if [ "$INTERCONNECT" == "ib" ]; then
    export mpi_options="-env IMPI_FABRICS=shm:dapl -env I_MPI_DAPL_PROVIDER=ofa-v2-ib0 -env I_MPI_DYNAMIC_CONNECTION=0 -env I_MPI_FALLBACK_DEVICE=0"
    export MPI_RDMA_MSGSIZE="16384,1048576,4194304"
elif [ "$INTERCONNECT" == "sriov" ]; then
    export mpi_options="-env IMPI_FABRICS=shm:ofa -env I_MPI_FALLBACK_DEVICE=0"
    #export MPI_RDMA_MSGSIZE="16384,1048576,4194304"
else
    export mpi_options="-env IMPI_FABRICS=shm:tcp"
fi

#define hosts in abaqus_v6.env file
# mp_file_system=(LOCAL,LOCAL)
# verbose=3
cat <<EOF >abaqus_v6.env
mp_host_list=[['$(sed "s/,/',$PPN],['/g" <<< $hostlist)',$PPN]]
mp_host_split=8
scratch="$PBS_O_WORKDIR"
mp_mpirun_options="$mpi_options"
license_server_type=FLEXNET
abaquslm_license_file="27000@${LICENSE_SERVER}"
EOF

# need to unset CCP_NODES otherwise Abaqus think it is running on HPC Pack
unset CCP_NODES

source /opt/intel/impi/*/bin64/mpivars.sh
export MPI_ROOT=$I_MPI_ROOT


ABQ2019="/opt/abaqus/applications/DassaultSystemes/SimulationServices/V6R2019x/linux_a64/code/bin/SMALauncher"
JOBNAME=$MODEL-$CORES

start_time=$SECONDS
$ABQ2019 -j $JOBNAME -input $MODEL.inp -cpus $CORES -interactive 
end_time=$SECONDS
task_time=$(($end_time - $start_time))


completed=$(grep "THE ANALYSIS HAS COMPLETED SUCCESSFULLY" $JOBNAME.sta)
if [[ ! -z $completed ]]; then 
    cat <<EOF >$APPLICATION.json
    {
    "version": "2019.x",
    "model": "$MODEL",
    "task_time": $task_time    
    }
EOF
fi
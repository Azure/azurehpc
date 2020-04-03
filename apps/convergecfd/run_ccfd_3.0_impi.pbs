#!/bin/bash

#PBS -N ConvergeCFD
#PBS -l select=2:ncpus=120:mpiprocs=120:mem=440gb:pool_name=compute2
#PBS -joe

APPLICATION=convergecfd
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/apps}
CCFD_VERSION=${CCFD_VERSION:-3.0.12}
EX_PATH=${EX_PATH:-${APP_INSTALL_DIR}/Convergent_Science/Example_Cases/$CCFD_VERSION/Internal_Combustion_Engines/Gasoline_spark_ignition_PFI}
CASE=${CASE:-SI8_engine_PFI_SAGE}
MPI=intelmpi
LICENSE_INFO=${LICENSE_INFO:-2765@10.1.0.5}

DATE=`date "+%Y%m%d-%H%M%S-%4N"`
CORES=$(cat $PBS_NODEFILE | wc -l)
NODES=$(cat $PBS_NODEFILE | sort -u | wc -l)

export RLM_LICENSE=$LICENSE_INFO
export PATH=${APP_INSTALL_DIR}/Convergent_Science/CONVERGE/$CCFD_VERSION/bin:$PATH

# Load module
module use ${APP_INSTALL_DIR}/Convergent_Science/Environment/modulefiles
module load CONVERGE/CONVERGE-IntelMPI/3.0.12

# Setup Intel MPI
export I_MPI_FABRICS="shm:ofi"
export I_MPI_FALLBACK_DEVICE=0
export I_MPI_DEBUG=4

MPI_OPTIONS="-hostfile $PBS_NODEFILE -np $CORES"

mkdir -p ${PBS_O_WORKDIR}/${PBS_JOBID}
cd ${PBS_O_WORKDIR}/${PBS_JOBID}
cp -R ${EX_PATH}/${CASE} .
ls -latr

cd ${CASE}


start_time=$SECONDS
CASE_OUTPUT=${PBS_O_WORKDIR}/${APPLICATION}_${CCFD_VERSION}_${NODES}n_${CASE}_${CORES}_${DATE}
mpirun \
    $MPI_OPTIONS \
    converge-${MPI} -S \
    > ${CASE_OUTPUT}.log
end_time=$SECONDS

clock_time=$(($end_time - $start_time))

if [ -f "${CASE_OUTPUT}.log" ]; then
    normal_exit=$(grep "normal termination" ${CASE_OUTPUT}.log)
    if [ -z "$normal_exit" ]; then
       cat <<EOF > out.json
{
    "job_status": "failed"
}
EOF
    exit -1
    fi

    t_time=$(grep "Total Simulation Run Time:" converge.log | tail -1 | awk '{ print $5 }' )
    cfd_setup=$(grep "CFD Simulation Setup" converge.log | tail -1 | cut -d'=' -f2 | awk '{ print $1 }')
    l_balance=$(grep "Load Balance" converge.log | tail -1 | cut -d'=' -f2 | awk '{ print $1 }')
    solve_t_e=$(grep "Solving Transport" converge.log | tail -1 | cut -d'=' -f2 | awk '{ print $1 }')
    m_surf=$(grep "Move Surface and Update Grid" converge.log | tail -1 | cut -d'=' -f2 | awk '{ print $1 }')
    u_bc=$(grep "Update Boundary Conditions" converge.log | tail -1 | cut -d'=' -f2 | awk '{ print $1 }')
    combustion=$(grep "Combustion" converge.log | tail -1 | cut -d'=' -f2 | awk '{ print $1 }')
    spray=$(grep "Spray" converge.log | tail -1 | cut -d'=' -f2 | awk '{ print $1 }')
    writing_outf=$(grep "Writing Output" converge.log | tail -1 | cut -d'=' -f2 | awk '{ print $1 }')

    echo ${CASE_OUTPUT}.json
    cat <<EOF > ${CASE_OUTPUT}.json
{
    "application": "$APPLICATION",
    "version": "$CCFD_VERSION",
    "model": "$CASE",
    "nodes": "$NODES",
    "cores": "$CORES",
    "total_wall_time": $t_time,
    "cfd_simulation_setup": $cfd_setup,
    "load balance": $l_balance,
    "solving_transport_equations": $solve_t_e,
    "move_surface_and_update_grid": $m_surf,
    "update_boundary_conditions": $u_bc,
    "combustion": $combustion,
    "spray": $spray,
    "writing_output_file": $writing_outf
}
EOF
fi

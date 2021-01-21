#!/bin/bash
MPI=${1-impi2018}
set -o pipefail

[[ -n $PBS_NODEFILE ]] && { ISPBS=true; JOBID=$PBS_JOBID; }
[[ -n $SLURM_NODELIST ]] && { ISSLURM=true; JOBID=$SLURM_JOBID; }

[[ "$ISPBS" = true ]] && num_ranks=$(wc -l <$PBS_NODEFILE)
[[ "$ISSLURM" = true ]] && num_ranks=$(($SLURM_NNODES * $(echo $SLURM_TASKS_PER_NODE | awk -F'(' '{print $1}')))

# Retrieve the VM size
AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}

case $MPI in
    impi2016)
        source /opt/intel/impi/5.1.3.223/bin64/mpivars.sh
        export I_MPI_FABRICS="shm:dapl"
        export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DAPL_PROVIDER=ofa-v2-ib0
        export I_MPI_DEBUG=4
        [[ "$ISPBS" = true ]] && mpi_options="-np 2 -ppn 1"
        host_option="-hosts"
        if [ -z $MPI_BIN ]; then
            IMB_ROOT=$I_MPI_ROOT/intel64/bin
        else
            IMB_ROOT=$MPI_BIN
        fi
    ;;
    impi2018)
        source /etc/profile
        module use /usr/share/Modules/modulefiles
        module load mpi/impi
        #source $MPI_BIN/mpivars.sh
        export I_MPI_FABRICS="shm:ofa"
        export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DEBUG=4
        [[ "$ISPBS" = true ]] && mpi_options="-hostfile $PBS_NODEFILE -np $num_ranks"
        if [ -z $MPI_BIN ]; then
            IMB_ROOT=$I_MPI_ROOT/intel64/bin
        else
            IMB_ROOT=$MPI_BIN
        fi
    ;;
    impi2019)
        source /etc/profile
        module use /usr/share/Modules/modulefiles
        module load mpi/impi-2019
        #source $MPI_BIN/mpivars.sh -ofi_internal
        export I_MPI_FABRICS="shm:ofi"
        #export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DEBUG=4
        export FI_PROVIDER=mlx
        [[ "$ISPBS" = true ]] && mpi_options="-hostfile $PBS_NODEFILE -np $num_ranks"
        if [ -z $MPI_BIN ]; then
            IMB_ROOT=$I_MPI_ROOT/intel64/bin
        else
            IMB_ROOT=$MPI_BIN
        fi
    ;;
    ompi)
        source /etc/profile
        module use /usr/share/Modules/modulefiles
        module load mpi/hpcx
        mpi_options+=" -bind-to core"
        mpi_options+=" -mca coll_hcoll_enable 1 -x HCOLL_ENABLE_MCAST_ALL=1"
        case $AZHPC_VMSIZE in
            standard_hb120rs_v2|standard_hb60rs)
                mpi_options+=" -x HCOLL_SBGP_BASESMSOCKET_GROUP_BY=numa"
            ;;
        esac
        [[ "$ISPBS" = true ]] && mpi_options+=" -hostfile $PBS_NODEFILE -np $num_ranks"
        IMB_ROOT=$HPCX_MPI_TESTS_DIR/imb
    ;;
esac

#echo $mpi_options
mpirun $mpi_options \
    $IMB_ROOT/IMB-MPI1 Allreduce -npmin $num_ranks \
    -iter 10000 \
    -msglog 3:4 -time 1000000 | tee output.log

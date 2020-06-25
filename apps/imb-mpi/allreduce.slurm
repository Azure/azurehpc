#!/bin/bash
#SBATCH --nodes=2
#SBATCH --exclusive
#SBATCH --output=allreduce_%A.out
#SBATCH --job-name allreduce

MPI=${1-impi2018}
set -o pipefail

case $MPI in
    impi2016)
        source /opt/intel/impi/5.1.3.223/bin64/mpivars.sh
        export I_MPI_FABRICS="shm:dapl"
        export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DAPL_PROVIDER=ofa-v2-ib0
        export I_MPI_DEBUG=4
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
        export FI_PROVIDER=verbs
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
        mpi_options+=" --map-by core"
        IMB_ROOT=$HPCX_MPI_TESTS_DIR/imb
    ;;
esac

num_tasks=$(($SLURM_NNODES * $(echo $SLURM_TASKS_PER_NODE | awk -F'(' '{print $1}')))

mpirun $mpi_options \
    $IMB_ROOT/IMB-MPI1 Allreduce -npmin $num_tasks \
    -iter 10000 \
    -msglog 3:4 -time 1000000

#!/bin/bash
MPI=$1
set -o pipefail
source /etc/profile
module use /usr/share/Modules/modulefiles

num_ranks=$(wc -l <$PBS_NODEFILE)

case $MPI in
    impi2018)
        module load mpi/impi
        #source $MPI_BIN/mpivars.sh
        export I_MPI_FABRICS="shm:ofa"
        export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DEBUG=4
        mpi_options="-hostfile $PBS_NODEFILE -np $num_ranks"
        if [ -z $MPI_BIN ]; then
            IMB_ROOT=$I_MPI_ROOT/intel64/bin
        else
            IMB_ROOT=$MPI_BIN
        fi
    ;;
    impi2019)
        module load mpi/impi-2019
        #source $MPI_BIN/mpivars.sh -ofi_internal
        export I_MPI_FABRICS="shm:ofi"
        #export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DEBUG=4
        export FI_PROVIDER=verbs
        mpi_options="-hostfile $PBS_NODEFILE -np $num_ranks"
        if [ -z $MPI_BIN ]; then
            IMB_ROOT=$I_MPI_ROOT/intel64/bin
        else
            IMB_ROOT=$MPI_BIN
        fi
    ;;
    ompi)
        module load mpi/hpcx

        mpi_options+=" --map-by core"
        mpi_options+=" -hostfile $PBS_NODEFILE -np $num_ranks"
        IMB_ROOT=$HPCX_MPI_TESTS_DIR/imb
    ;;
esac

echo $mpi_options
mpirun $mpi_options \
    $IMB_ROOT/IMB-MPI1 Allreduce -npmin $num_ranks \
    -iter 10000 \
    -msglog 3:4 -time 1000000 | tee output.log

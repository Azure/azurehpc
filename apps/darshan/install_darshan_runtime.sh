#!/bin/bash
NON_MPI=${1:-"0"}

SHARED_APP=${SHARED_APP:-/apps}
module use ${SHARED_APP}/modulefiles
module load spack/spack
source $SPACK_SETUP_ENV

sudo yum install -y python3 

if [ "$NON_MPI" == "1" ]; then
   spack install darshan-runtime+pbs~mpi%gcc@9.2.0
else
   spack install darshan-runtime+pbs^openmpi@4.0.3%gcc@9.2.0
fi

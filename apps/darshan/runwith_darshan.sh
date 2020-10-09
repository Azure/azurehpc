#!/bin/bash
SHARED_APP=${SHARED_APP:-/apps}
source /etc/profile
module use ${SHARED_APP}/modulefiles
module load spack/spack
source $SPACK_SETUP_ENV

# Test if darshan is installed
spack load darshan-runtime
if [ $? == 1 ]; then
    "echo Darshan is not installed, installed it"
    if ! rpm -q python3; then
        sudo yum install -y python3 
    fi
    spack install darshan-runtime+pbs^openmpi@4.0.3%gcc@9.2.0
    spack load darshan-runtime
fi

DARSHAN_RUNTIME_DIR=$(spack location -i darshan-runtime)
export LD_PRELOAD=${DARSHAN_RUNTIME_DIR}/lib/libdarshan.so
#export DARSHAN_LOG_DIR_PATH=/share/home/hpcuser/darshan_logs
#mkdir $DARSHAN_LOG_DIR_PATH

$@

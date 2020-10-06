#!/bin/bash
SHARED_APP=${SHARED_APP:-/apps}
source /etc/profile
module use ${SHARED_APP}/modulefiles
module load spack/spack
source $SPACK_SETUP_ENV

spack load darshan-runtime
DARSHAN_RUNTIME_DIR=$(spack location -i darshan-runtime)
export LD_PRELOAD=${DARSHAN_RUNTIME_DIR}/lib/libdarshan.so
#export DARSHAN_LOG_DIR_PATH=/share/home/hpcuser/darshan_logs
#mkdir $DARSHAN_LOG_DIR_PATH

$@

#!/bin/bash
set -o pipefail
nodes=$1
mpi=${2-impi2018}
mode=${3-ring}

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/common.sh"
source "$script_dir/pbs_helpers.sh"

# Set maximum job time to 20 minutes
PBS_MAX_WALLTIME="00:20:00"
make_uuid_str
job_group=$uuid_str

echo "submit job $job_group on $nodes"
echo "AZHPC_TELEMETRY_WRAPPER=$AZHPC_TELEMETRY_WRAPPER"
submit_job $job_group $nodes 1 $AZHPC_TELEMETRY_WRAPPER /apps/imb-mpi/ringpingpong.sh $mpi $mode

# Wait for all jobs to be finished
wait_alljobs $job_group

# Check job status, if any failed it will exit with an error code
check_jobstatus $job_group

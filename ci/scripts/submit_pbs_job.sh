#!/bin/bash
set -o pipefail
nodes=$1
ppn=$2


script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/common.sh"
source "$script_dir/pbs_helpers.sh"

# Set maximum job time to 30 minutes
PBS_MAX_WALLTIME="00:30:00"
make_uuid_str
job_group=$uuid_str

echo "submit job $job_group on $nodes nodes with ppn=$ppn"
shift; shift
command=$@
echo "command is : $command"
echo "AZHPC_TELEMETRY_WRAPPER=$AZHPC_TELEMETRY_WRAPPER"
submit_job $job_group $nodes $ppn $AZHPC_TELEMETRY_WRAPPER $command

# Wait for all jobs to be finished
wait_alljobs $job_group

# TODO : Add data collection and push them in blobs

# Check job status, if any failed it will exit with an error code
check_jobstatus $job_group

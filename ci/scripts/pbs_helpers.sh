#!/bin/bash
# Define a very long maximum walltime
PBS_MAX_WALLTIME="24:00:00"

function wait_alljobs()
{
    local jobgroup=$1
    # Wait for all jobs to be finished
    local active_jobs=$(qstat -aw | grep $jobgroup | wc -l)
    while [ $active_jobs -ne 0 ]; do
        echo "There are $active_jobs active jobs"
        sleep 60
        active_jobs=$(qstat -aw | grep $jobgroup | wc -l)
    done

    echo "All jobs finished"
}

function check_jobstatus()
{
    local jobgroup=$1
    # Get the full list of jobs
    qstat -H | grep $jobgroup &>/dev/null || exit 1
    local job_list=$(qstat -H | grep $jobgroup | cut -d'.' -f1 | xargs)

    # For each job test the exit code, in case of failure report it and set the error flag so we can exit with an error
    local test_failure=0
    for jobid in $job_list; do
        local exit_status=$(qstat -fx $jobid | grep Exit_status | xargs | cut -d' ' -f3)
        if [ $exit_status != 0 ]; then
            echo "ERROR $exit_status: Failure while running job $jobid"
            qstat -fx $jobid
            tail -n50 *.o$jobid
            test_failure=1
        else
            echo "$jobid OK"
            tail -n10 *.o$jobid
        fi
    done

    if [ $test_failure -ne 0 ]; then
        exit $test_failure
    fi
}

function get_pool_list()
{
    pbsnodes -avS &>/dev/null || exit 1
    echo $(pbsnodes -av | grep pool_name | cut -d'=' -f2 | sort | uniq | xargs)
}

function get_node_count()
{
    local pool=${1-"="}
    pbsnodes -avS &>/dev/null || exit 1
    echo $(pbsnodes -a -F dsv | grep "$pool" | wc -l)
}

function list_nodes()
{
    local pool=${1-"="}
    pbsnodes -a -F dsv | grep "$pool"
}

function get_node_list()
{
    local pool=${1-"="}
    echo $(pbsnodes -a -F dsv | grep "$pool" | cut -d'|' -f1 | cut -d'=' -f2 | sort)
}

function get_node_core_count()
{
    local pool=${1-""}
    pbsnodes -avS &>/dev/null || exit 1
    echo $(pbsnodes -a -F dsv | grep "=$pool|" | cut -d'|' -f5 | head -n1 | cut -d'=' -f2)
}

function submit_job()
{
    local job_name=$1
    local pool_name=$2
    local node_count=$3
    local ppn=$4
    local script=$5

    qsub -l walltime=$PBS_MAX_WALLTIME -N $job_name -k oe \
            -j oe -l select=$node_count:ncpus=$ppn:mpiprocs=$ppn:pool_name=$pool_name,place=scatter:excl \
            -- $script
    if [ "$?" -ne "0" ]; then
        echo "Unable to submit job"
        exit 1
    fi
}
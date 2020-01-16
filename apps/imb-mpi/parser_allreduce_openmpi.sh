#!/bin/bash
source /etc/profile
module use /usr/share/Modules/modulefiles
module load mpi/hpcx

file=${1-output.log}
grep -A3 "t_min" ${file} | tr -s ' ' | \
    jq --slurp --raw-input --raw-output 'split("\n") | .[2:-1] | map(split(" ")) | map({"bytes": .[1]|tonumber, "iter": .[2]|tonumber, "t_min": .[3]|tonumber, "t_max": .[4]|tonumber, "t_avg": .[5]|tonumber})' > metrics.json

mpi_version=$(mpirun --version | head -n1)

cat <<EOF >app.json
{
    "app": "imb-mpi",
    "benchmark": "allreduce",
    "mpi": "ompi",
    "mpi_version": "$mpi_version"
}
EOF


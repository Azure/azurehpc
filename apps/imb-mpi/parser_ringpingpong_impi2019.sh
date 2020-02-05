#!/bin/bash
source /etc/profile
module load mpi/impi-2019

file=output.log
cat $file | tr -s ' ' | \
    jq --slurp --raw-input --raw-output 'split("\n") | .[2:-1] | map(split(" ")) | map({"from": .[0], "to": .[1], "t_avg": .[2]|tonumber})' > metrics.json

mpi_version=$(mpirun --version | head -n1)

cat <<EOF >app.json
{
    "app": "imb-mpi",
    "benchmark": "pingpong",
    "mpi": "impi2019",
    "mpi_version": "$mpi_version"
}
EOF


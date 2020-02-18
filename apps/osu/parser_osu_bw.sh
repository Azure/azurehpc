#!/bin/bash
source /etc/profile
module use /usr/share/Modules/modulefiles
module load mpi/hpcx

file=output.log
cat $file | tr -s ' ' | \
    jq --slurp --raw-input --raw-output 'split("\n") | .[2:-1] | map(split(" ")) | map({"from": .[0], "to": .[1], "bw": .[2]|tonumber})' > metrics.json

mpi_version=$(mpirun --version | head -n1)

cat <<EOF >app.json
{
    "app": "osu benchmarks",
    "benchmark": "osu_bw",
    "mpi": "ompi",
    "mpi_version": "$mpi_version"
}
EOF
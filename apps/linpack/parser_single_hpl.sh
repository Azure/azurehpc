#!/bin/bash
source /etc/profile
module use /usr/share/Modules/modulefiles
module load mpi/impi-2019

output_file=hpl.out

grep -A2 " Gflops" $output_file | tail -n1 | tr -s ' ' | \
    jq --slurp --raw-input --raw-output 'split("\n") | .[0:-1] | map(split(" ")) | map({"tv": .[0], "N": .[1]|tonumber, "NB": .[2]|tonumber, "P": .[3]|tonumber, "Q": .[4]|tonumber, "time": .[5]|tonumber, "gflops": .[6]|tonumber})' > metrics.json

mpi_version=$(mpirun --version | head -n1)

cat <<EOF >app.json
{
    "app": "hpl",
    "benchmark": "linpack",
    "mpi": "impi2019",
    "mpi_version": "$mpi_version"
}
EOF


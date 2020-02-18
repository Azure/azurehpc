#!/bin/bash
MPI=$1
source /etc/profile
module use /usr/share/Modules/modulefiles
case $MPI in
    impi2018)
        module load mpi/impi
    ;;
    impi2019)
        module load mpi/impi-2019
    ;;
    ompi)
        module load mpi/hpcx
    ;;
esac

file=output.log
grep -A3 "t_min" ${file} | tr -s ' ' | \
    jq --slurp --raw-input --raw-output 'split("\n") | .[2:-1] | map(split(" ")) | map({"bytes": .[1]|tonumber, "iter": .[2]|tonumber, "t_min": .[3]|tonumber, "t_max": .[4]|tonumber, "t_avg": .[5]|tonumber})' > metrics.json

mpi_version=$(mpirun --version | head -n1)

cat <<EOF >app.json
{
    "app": "imb-mpi",
    "benchmark": "allreduce",
    "mpi": "$MPI",
    "mpi_version": "$mpi_version"
}
EOF


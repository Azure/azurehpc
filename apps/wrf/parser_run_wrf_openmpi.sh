#!/bin/bash
source /etc/profile
module load mpi/openmpi-4.0.3

result="rsl.out.00000000"

if [ -e $result ]; then
    success=$(grep "SUCCESS COMPLETE WRF" $result)
    if [ "$success" == "" ]; then
        echo "wrong run"
        exit 1
    fi
else
    echo "$result not found"
    exit 1
fi

mpi_version=$(mpirun --version | head -n1)
app_version=$(grep MODEL $result | cut -d' ' -f2)
# TODO : see https://github.com/akirakyle/WRF_benchmarks/blob/master/scripts/wrf_stats to collect metrics

cat <<EOF >app.json
{
    "app": "wrf",
    "version": "$app_version",
    "mpi": "ompi",
    "mpi_version": "$mpi_version"
}
EOF
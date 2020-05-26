#!/bin/bash

for dir in "$@"; do
    for log in $dir/install/*_run_benchmark.log; do

        clients=$(grep READ: $log | wc -l)

        read_bw=($(grep READ: $log | sed 's/.*bw=//g;s/MiB.*//g'))
        read_tot=$(IFS=+; echo "${read_bw[*]}" | bc )

        write_bw=($(grep WRITE: $log | sed 's/.*bw=//g;s/MiB.*//g'))
        write_tot=$(IFS=+; echo "${write_bw[*]}" | bc )

        echo "$clients $read_tot $write_tot"

    done
done

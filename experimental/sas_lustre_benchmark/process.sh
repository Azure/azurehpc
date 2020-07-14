#!/bin/bash

for run_dir in "$@"
do
    reads="$(grep "read throughput rate" $run_dir/install/*_rhel_iotest.log | sed 's/ *read throughput rate: *//g;s/ megabytes.*$//g' | tr '\n' ' ')"
    av_reads=$(echo "($(tr ' ' '+' <<< $reads)0) / $(wc -w <<< $reads )" | bc -l)
    echo "$run_dir READ $av_reads $reads"
    writes="$(grep "write throughput rate" $run_dir/install/*_rhel_iotest.log | sed 's/ *write throughput rate: *//g;s/ megabytes.*$//g' | tr '\n' ' ')"
    av_writes=$(echo "($(tr ' ' '+' <<< $writes)0) / $(wc -w <<< $writes )" | bc -l)
    echo "$run_dir WRITE $av_writes $writes"
done

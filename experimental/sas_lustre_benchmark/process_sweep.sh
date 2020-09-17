#!/bin/bash

prefix=$1
oss_sku=$2
oss_instances=$3
client_sku=$4
client_instances=$5

for __oss_vm_type__ in $oss_sku; do
    for __oss_instances__ in $oss_instances; do
        for __client_vm_type__ in $client_sku; do
            for __client_vm_instances__ in $client_instances; do
               
                name="$prefix-${__oss_instances__}-$(cut -d'_' -f2 <<< $__oss_vm_type__)-${__client_vm_instances__}-$(cut -d'_' -f2 <<< $__client_vm_type__)"
                run_dir="azhpc_install_$name"

                if [ -d $run_dir ]; then
                    reads="$(grep "read throughput rate" $run_dir/install/*_rhel_iotest.log | sed 's/ *read throughput rate: *//g;s/ megabytes.*$//g' | tr '\n' ' ')"
                    av_reads=$(echo "($(tr ' ' '+' <<< $reads)0) / $(wc -w <<< $reads )" | bc -l)
                    writes="$(grep "write throughput rate" $run_dir/install/*_rhel_iotest.log | sed 's/ *write throughput rate: *//g;s/ megabytes.*$//g' | tr '\n' ' ')"
                    av_writes=$(echo "($(tr ' ' '+' <<< $writes)0) / $(wc -w <<< $writes )" | bc -l)
                
                    echo "$__oss_vm_type__ $__oss_instances__ $__client_vm_type__ $__client_vm_instances__ $av_reads $av_writes"
                fi
               
            done
        done
    done
done

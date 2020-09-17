#!/bin/bash

echo "getting rhel_iotest from SAS website"
./get_rhel_iotest.sh

prefix=$1
oss_sku=$2
oss_instances=$3
client_sku=$4
client_instances=$5

nskip=0
iskip=0

for __oss_vm_type__ in $oss_sku; do
    for __oss_instances__ in $oss_instances; do
        for __client_vm_type__ in $client_sku; do
            for __client_vm_instances__ in $client_instances; do

                echo "__oss_instances__=$__oss_instances__"
                echo "__oss_vm_type__=$__oss_vm_type__"
                echo "__client_vm_type__=$__client_vm_type__"
                echo "__client_vm_instances__=$__client_vm_instances__"

                if [ $iskip -lt $nskip ]; then
                    echo "skipping iteration"
                    iskip=$(($iskip + 1))
                    continue
                fi
                
                name="$prefix-${__oss_instances__}-$(cut -d'_' -f2 <<< $__oss_vm_type__)-${__client_vm_instances__}-$(cut -d'_' -f2 <<< $__client_vm_type__)"
                
                sed "s/__resource_group__/${name}/g;s/__oss_instances__/${__oss_instances__}/g;s/__oss_vm_type__/${__oss_vm_type__}/g;s/__client_vm_type__/${__client_vm_type__}/g;s/__client_vm_instances__/${__client_vm_instances__}/g" config.json >${name}.json

                azhpc-build -c ${name}.json
                azhpc-destroy -c ${name}.json --force --no-wait
            done
        done
    done
done

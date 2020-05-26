#!/bin/bash

function run_benchmark {
    name=$1
    storage_sku=$2
    storage_instances=$3
    client_instances=$4
    client_accelerated_networking=$5

    resource_group=$(whoami)-$name
    
    sed "s/__resource_group__/${resource_group}/g;s/__storage_sku__/${storage_sku}/g;s/__storage_instances__/${storage_instances}/g;s/__client_instances__/${client_instances}/g;s/__client_accelerated_networking__/${client_accelerated_networking}/g" config.json.tpl >${name}.json
    
    pushd scripts
    rm -f config.json
    ln -s ../${name}.json config.json
    popd

    azhpc-build -c ${name}.json
    azhpc-destroy -c ${name}.json --force
}

run_benchmark beegfs-s2-c16-an Standard_F48s_v2 2 16 true
run_benchmark beegfs-s2-c16 Standard_F48s_v2 2 16 false
run_benchmark beegfs-s8-c16-an Standard_D48s_v3 8 16 true
run_benchmark beegfs-s8-c16 Standard_D48s_v3 8 16 false

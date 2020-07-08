#!/bin/bash

for iter in $(seq -w 1 10); do
    for sku in F4s_v2 F8s_v2 F16s_v2 F32s_v2; do
        name="$USER-latency-test-${sku/_/-}-$iter"
        sed "s/__resource_group__/${name}/g;s/__ppg_name__/${name}/g;s/__vm_sku__/Standard_${sku}/g" config.json >${name}.json

        azhpc-build -c ${name}.json
        azhpc-destroy -c ${name}.json --force --no-wait
    done
done

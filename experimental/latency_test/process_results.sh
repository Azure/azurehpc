#!/bin/bash

for iter in $(seq -w 1 10); do
    for sku in D4s_v3 D8s_v3 D16s_v3 D64s_v3 F4s_v2 F8s_v2 F16s_v2 F72s_v2; do
        name="azhpc_install_$(whoami)-latency-test-${sku/_/-}-$iter-no-agents"
        logfile=$name/install/*_run_sockperf.log
        
        if [ -f $logfile ]; then
            rtt=$(grep Summary $logfile | cut -d' ' -f6)
            range=$(grep "\-\-\->" $logfile | cut -d'=' -f2 | tr '\n' ' ')
            echo $sku $iter $rtt $range
        fi
    done
done


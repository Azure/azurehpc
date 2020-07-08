#!/bin/bash

echo "SKU METRIC ITERATION SOCKPERF SOCKPERF_VMA"

for name in "$@"; do
    sku_and_iter_tmp=${name##azhpc_install_*-latency-test-}
    sku_tmp=${sku_and_iter_tmp%-*}
    sku=${sku_tmp/-/_}
    iter=${sku_and_iter_tmp##*-}

    logfiles=$name/install/*_run_sockperf*.log
    for result in avg 99.000 99.900 99.990 99.999 \<MAX\>; do

        if [ "$result" = "avg" ]; then
            rtt=$(grep " Round trip is " $logfiles | cut -d' ' -f6 | tr '\n' ' ')
            echo $sku avg $iter $rtt
        else                
            rtt=$(grep " $result " $logfiles | cut -d'=' -f2 | tr '\n' ' ')
            if [ "$result" = "<MAX>" ]; then
                echo $sku max $iter $rtt
            else
                echo $sku "=TEXT($result,\"0.000\")" $iter $rtt
            fi
        fi
    
    done
done
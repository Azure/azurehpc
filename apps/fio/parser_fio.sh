#!/bin/bash

source /etc/profile
module use /usr/share/Modules/modulefiles

file=output.log
#grep -A3 "t_min" ${file} | tr -s ' ' | \
#    jq --slurp --raw-input --raw-output 'split("\n") | .[2:-1] | map(split(" ")) | map({"bytes": .[1]|tonumber, "iter": .[2]|tonumber, "t_min": .[3]|tonumber, "t_max": .[4]|tonumber, "t_avg": .[5]|tonumber})' > metrics.json

grep 'READ\|WRITE' output.log | sed 's/(/( /g;s/)/ )/g;s/M/ M/g;s/:/ :/g' | tr -s ' ' | jq --slurp --raw-input --raw-output 'split("\n")  | .[:-1] | map(split(" ")) |  map({"bytes": .[1], "bandwidth": .[6]|tonumber})' > metrics.json

cat <<EOF >app.json
{
    "app": "fio",
    "benchmark": "readwrite",
    "filesystem": "beeond"
}
EOF

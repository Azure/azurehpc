#!/bin/bash
output_file=hpl.out

grep -A2 " Gflops" $output_file | tail -n1 | tr -s ' ' | \
    jq --slurp --raw-input --raw-output 'split("\n") | .[0:-1] | map(split(" ")) | map({"tv": .[0], "N": .[1]|tonumber, "NB": .[2]|tonumber, "P": .[3]|tonumber, "Q": .[4]|tonumber, "time": .[5]|tonumber, "gflops": .[6]|tonumber})' > metrics.json

hpl_version=$(grep "HPLinpack" hpl.out | cut -d'-' -f1 | xargs)
cat <<EOF >app.json
{
    "app": "hpl",
    "benchmark": "linpack",
    "version": "$hpl_version"
}
EOF


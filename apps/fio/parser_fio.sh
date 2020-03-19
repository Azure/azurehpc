#!/bin/bash
FILESYSTEM=$1

grep 'READ\|WRITE' *.out | sed 's/(//g;s/),//g;s/MB/ MB/g;s/:/ :/g;s/_/ /g;s/.out//g' | tr -s ' ' | jq --slurp --raw-input --raw-output 'split("\n")  | .[:-1] | map(split(" ")) |  map({"io_type": .[2], "file_size": .[3], "block_size": .[4], "nbclients": .[5]|tonumber, "bw": .[10]|tonumber, "unit": .[11]})' > metrics.json

cat <<EOF >app.json
{
    "app": "fio",
    "benchmark": "readwrite",
    "filesystem": "$FILESYSTEM"
}
EOF

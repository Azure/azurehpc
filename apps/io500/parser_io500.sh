#!/bin/bash

logfile=

# RESULT
sed -n -e '/Summary/,$p' $logfile |grep RESULT | sed 's/\[RESULT\]/result valid/g;s/\[RESULT-invalid\]/result invalid/g;s/  */ /g' | jq --slurp --raw-input --raw-output 'split("\n") | map(split(" ")) | .[:-1] | map({"type": .[0], "status": .[1], "test": .[3], "phase": .[4]|tonumber, "test": .[5], "result": .[6]|tonumber, "metric": .[7], "time": .[10]|tonumber})'

# SCORE
sed -n -e '/Summary/,$p' $logfile |grep SCORE | sed 's/\[SCORE\]/score valid/g;s/\[SCORE-invalid\]/score invalid/g;s/  */ /g' | jq --slurp --raw-input --raw-output 'split("\n") | map(split(" ")) | .[:-1] | map({"type": .[0], "status": .[1], "Bandwidth": .[3]|tonumber, "IOPS": .[7]|tonumber, "Total": .[11]})'

#!/bin/bash

source /etc/profile
module load mpi/openmpi-4.0.2

logfile=~/io500.out


# RESULT
cat $logfile |grep RESULT | sed 's/\[RESULT\]/result true/g;s/\[RESULT-invalid\]/result false/g;s/  */ /g' | jq --slurp --raw-input --raw-output 'split("\n") | map(split(" ")) | .[:-1] | map({"name": .[5], "type": .[2], "valid": .[1]|test("true"), "result": .[6]|tonumber, "metric": .[7], "time": .[10]|tonumber})' >result.json

# SCORE
cat $logfile |grep SCORE | sed 's/\[SCORE\]/score true/g;s/\[SCORE-invalid\]/score false/g;s/  */ /g' | jq --slurp --raw-input --raw-output 'split("\n") | map(split(" ")) | .[:-1] | map([{"name": "bandwidth", "type": "SCORE", "valid": .[1]|test("true"), "result": .[3]|tonumber, "metric": .[4]}, {"name": "iops", "type": "SCORE", "valid": .[1]|test("true"), "result": .[7]|tonumber, "metric": .[8]},{"name": "total", "type": "SCORE", "valid": .[1]|test("true"), "result": .[11]|tonumber, "metric": "io500"}]) |.[0]' >score.json

# COMBINE
jq '. += $score' --argjson score "$(<score.json)" result.json > metrics.json

mpi_version=$(mpirun --version | head -n1)

cat <<EOF >app.json
{
    "app": "io500",
    "benchmark": "io500",
    "mpi": "ompi",
    "mpi_version": "$mpi_version"
}
EOF

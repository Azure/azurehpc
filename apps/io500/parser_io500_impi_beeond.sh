#!/bin/bash
source /etc/profile
module load mpi/impi_2018.4.274

logfile=stdout.log

# RESULT
cat $logfile |grep RESULT | sed 's/\[RESULT\]/result true/g;s/\[RESULT-invalid\]/result false/g;s/  */ /g' | jq --slurp --raw-input --raw-output 'split("\n") | map(split(" ")) | .[:-1] | map({"name": .[2], "type": "result", "valid": .[1]|test("true"), "result": .[3]|tonumber, "metric": .[4], "time": .[7]|tonumber})' >result.json

# SCORE
cat $logfile |grep SCORE | sed 's/\[SCORE\]/score true/g;s/\[SCORE-invalid\]/score false/g;s/  */ /g' | jq --slurp --raw-input --raw-output 'split("\n") | map(split(" ")) | .[:-1] | map([{"name": "bandwidth", "type": "score", "valid": .[1]|test("true"), "result": .[3]|tonumber, "metric": .[4]}, {"name": "iops", "type": "score", "valid": .[1]|test("true"), "result": .[7]|tonumber, "metric": .[8]},{"name": "total", "type": "score", "valid": .[1]|test("true"), "result": .[11]|tonumber, "metric": "io500"}]) |.[0]' >score.json

# COMBINE
jq '. += $score' --argjson score "$(<score.json)" result.json > metrics.json

mpi_version=$(mpirun --version | head -n1)

cat <<EOF >app.json
{
    "app": "io500",
    "benchmark": "io500",
    "mpi": "impi",
    "mpi_version": "$mpi_version",
    "storage": "beeond"
}
EOF

#!/bin/bash
set -e
# Validate that $n is $n+1 value

error=0
while test $# -gt 0
do
    arg=$1
    value=$2
    echo "testing $arg=$value"
    if [ "$arg" != "$value" ]; then
        echo "ERROR : expected value $value is differrent from $arg"
        error=1
    fi
    shift
    shift
done

exit $error

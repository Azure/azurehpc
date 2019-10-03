#!/bin/bash

source "$azhpc_dir/libexec/common.sh"

DEBUG_ON=0
COLOR_ON=1

config_file=test.json

function test_read_value
{
    read_value_str=$1
    expected_val=$2
    echo -n "testing read_value [ $1 = $2 ]... "
    read_value val "$read_value_str"
    if [ "$val" = "$expected_val" ]; then
        echo "SUCCESS"
    else
        echo "FAILURE [ value = \"$val\" ]"
    fi
}

test_read_value .variables.baz baz
test_read_value .variables.bar barbaz
test_read_value .variables.foo foobarbaz

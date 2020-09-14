#!/bin/bash
var_name=$1
var_value=$2

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cat <<EOF >> $DIR/group_vars/all.yml
$var_name: $var_value
EOF
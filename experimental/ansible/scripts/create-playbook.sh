#!/bin/bash
CONFIG=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

config_file=$DIR/../../$CONFIG

function read_value {
    read $1 <<< $(jq -r "$2" $config_file)
}


cat <<EOF > playbook.yml
---
EOF

for resource_name in $(jq -r ".resources | keys | @tsv" $config_file); do
    read_value resource_type ".resources.$resource_name.type"

    case $resource_type in
        vm)
cat <<EOF >> playbook.yml
  - hosts: $resource_name
    become: true
    roles:

EOF        ;;
        vmss)
        ;;
    esac
        
done
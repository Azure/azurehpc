#!/bin/bash
CONFIG=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

config_file=$DIR/../../$CONFIG
PLAYBOOK=$DIR/playbook.yml

function read_value {
    read $1 <<< $(jq -r "$2" $config_file)
}


cat <<EOF > $PLAYBOOK
---

EOF

for resource_name in $(jq -r ".resources | keys_unsorted | @tsv" $config_file); do
    read_value resource_type ".resources.$resource_name.type"

    case $resource_type in
        vm)
cat <<EOF >> $PLAYBOOK
  - hosts: $resource_name
    become: true
    roles:
EOF
        ;;
        vmss)
cat <<EOF >> $PLAYBOOK
  - hosts: ${resource_name}*
    become: true
    roles:
EOF
        ;;
    esac

    # Add roles. Each role is the tag name
    for tag in $(jq -r ".resources.$resource_name.tags | @tsv" $config_file); do
cat <<EOF >> $PLAYBOOK
      - $tag
EOF
    done

echo "" >> $PLAYBOOK
done

cat <<EOF >> $PLAYBOOK
...
EOF
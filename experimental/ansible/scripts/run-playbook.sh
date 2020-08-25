#!/bin/bash
inventory=$1
private_key=$2
remote_user=$3

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Disable SSH host checking to avoid prompting
export ANSIBLE_HOST_KEY_CHECKING=False

if [ -n "$private_key" ]; then
    key_options="--private-key $private_key -u $remote_user"
else
    key_options=""
fi
ansible-playbook -v $key_options -i $inventory $DIR/playbook.yml

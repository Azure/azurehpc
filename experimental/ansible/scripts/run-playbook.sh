#!/bin/bash
hosts=$1

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ansible-playbook -i $hosts $DIR/cluster.yml
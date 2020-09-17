#!/bin/bash
private_key=$1
remote_user=$2
ssh_bastion=$3

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create the SSH proxy command to run thru the bastion
mkdir -p $DIR/group_vars

cat <<EOF > $DIR/group_vars/all.yml
---

ansible_ssh_common_args: '-o ProxyCommand="ssh -q -i $private_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $remote_user@$ssh_bastion"'
EOF

# Add the roles path

cat <<EOF > $DIR/../ansible.cfg
[defaults]
roles_path = $DIR/../../scripts/roles
EOF

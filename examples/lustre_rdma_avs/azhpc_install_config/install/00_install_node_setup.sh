#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )/.."

tag=linux

if [ ! -f "hostlists/$tag" ]; then
    echo "no hostlist ($tag), exiting"
    exit 0
fi

# wait for DNS to update for all hostnames
for h in $(<hostlists/$tag); do
    until host $h >/dev/null 2>&1; do
        echo "Waiting for host - $h (sleeping for 5 seconds)"
        sleep 5
    done
done

if [ "$1" != "" ]; then
    tag=tags/$1
else
    sudo yum install -y epel-release > install/00_install_node_setup.log 2>&1
    sudo yum install -y pssh nc >> install/00_install_node_setup.log 2>&1

    # setting up keys
    cat <<EOF > ~/.ssh/config
    Host *
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
        LogLevel ERROR
EOF
    cp hpcadmin_id_rsa.pub ~/.ssh/id_rsa.pub
    cp hpcadmin_id_rsa ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/config
    chmod 644 ~/.ssh/id_rsa.pub

fi

pssh -p 50 -t 0 -i -h hostlists/$tag 'rpm -q rsync || sudo yum install -y rsync' >> install/00_install_node_setup.log 2>&1

prsync -p 50 -a -h hostlists/$tag ~/azhpc_install_config ~ >> install/00_install_node_setup.log 2>&1
prsync -p 50 -a -h hostlists/$tag ~/.ssh ~ >> install/00_install_node_setup.log 2>&1

pssh -p 50 -t 0 -i -h hostlists/$tag 'echo "AcceptEnv PSSH_NODENUM PSSH_HOST" | sudo tee -a /etc/ssh/sshd_config' >> install/00_install_node_setup.log 2>&1
pssh -p 50 -t 0 -i -h hostlists/$tag 'sudo systemctl restart sshd' >> install/00_install_node_setup.log 2>&1
pssh -p 50 -t 0 -i -h hostlists/$tag "echo 'Defaults env_keep += \"PSSH_NODENUM PSSH_HOST\"' | sudo tee -a /etc/sudoers" >> install/00_install_node_setup.log 2>&1

#!/bin/bash

cd ~/azhpc_install_config

sudo yum install -y epel-release > step_0_install_node_setup.log 2>&1
sudo yum install -y pssh nc >> step_0_install_node_setup.log 2>&1

# setting up keys
cat <<EOF > ~/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF
cp _id_rsa.pub ~/.ssh/id_rsa.pub
cp _id_rsa ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/config
chmod 644 ~/.ssh/id_rsa.pub

prsync -p 50 -a -h hostlists/linux ~/azhpc_install_config ~ >> step_0_install_node_setup.log 2>&1
prsync -p 50 -a -h hostlists/linux ~/.ssh ~ >> step_0_install_node_setup.log 2>&1

pssh -p 50 -t 0 -i -h hostlists/linux 'echo "AcceptEnv PSSH_NODENUM PSSH_HOST" | sudo tee -a /etc/ssh/sshd_config' >> step_0_install_node_setup.log 2>&1
pssh -p 50 -t 0 -i -h hostlists/linux 'sudo systemctl restart sshd' >> step_0_install_node_setup.log 2>&1
pssh -p 50 -t 0 -i -h hostlists/linux "echo 'Defaults env_keep += \"PSSH_NODENUM PSSH_HOST\"' | sudo tee -a /etc/sudoers" >> step_0_install_node_setup.log 2>&1
echo 'Step 1 : '
start_time=$SECONDS
## copying files
pssh -p 50 -t 0 -i -h hostlists/tags/ "cd azhpc_install_config;  scripts/" >> step_1_.log 2>&1
echo "    duration: $(($SECONDS - $start_time)) seconds"

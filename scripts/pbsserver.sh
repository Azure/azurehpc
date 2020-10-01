#!/bin/bash
set -e

admin_user=hpcadmin

# Check to see which OS this is running on. 
os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
os_maj_ver=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
echo "OS Release: $os_release"
echo "OS Major Version: $os_maj_ver"

# Check to see if pbs is already installed
if [ -f "/etc/pbs.conf" ];then 
    echo "PBSPro already installed"
    exit 0
fi

# PBS needs to be installed
# Find the unzipped PBS directory and change to it
dir_name=$(ls -dr */ | grep pbs | tail -n1)
cd $dir_name

if [ "$os_release" == "centos" ];then
    if [ "$os_maj_ver" == "7" ] || [ "$os_maj_ver" == "8" ];then
            install_file=$(ls *-server*.rpm)
            yum install -y $install_file
    else
        echo "Not sure what to do with Version: $os_maj_ver"
    fi  
elif [ "$os_release" == "ubuntu" ] && [ "$os_maj_ver" == "18.04" ];then
    install_file=$(ls *-server_*.deb)
    apt install ./$install_file -y
    apt install libpq-dev postgresql postgresql-contrib -y
    adduser pbsdata  --home /home/pbsdata --gecos "PBS DATA,1,1,1" --disabled-password
else
    echo "Unsupported Release: $os_release"
fi

# Configure PBS
systemctl enable pbs 
systemctl start pbs 
/opt/pbs/bin/qmgr -c "s s managers += ${admin_user}@*"
/opt/pbs/bin/qmgr -c 's s flatuid=t'
/opt/pbs/bin/qmgr -c 's s job_history_enable=t'
/opt/pbs/bin/qmgr -c 'c r pool_name type=string,flag=h'

# Update the sched_config file to schedule jobs that request pool_name
sed -i "s/^resources: \"ncpus,/resources: \"ncpus, pool_name,/g" /var/spool/pbs/sched_priv/sched_config
systemctl restart pbs 

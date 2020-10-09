#!/bin/bash
# arg: $1 = pbs_server
pbs_server=$1

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

# Change to the openpbs dir
cd openpbs

PBS_SERVER_STRING="CHANGE_THIS_TO_PBS_SERVER_HOSTNAME"
if [ "$os_release" == "centos" ];then
    if [ "$os_maj_ver" == "7" ];then
        PBS_SERVER_STRING="CHANGE_THIS_TO_PBS_PRO_SERVER_HOSTNAME"
    fi
    if [ "$os_maj_ver" == "7" ] || [ "$os_maj_ver" == "8" ];then
            install_file=$(ls *-execution-*.rpm)
            yum install -y $install_file
    else
        echo "Not sure what to do with Version: $os_maj_ver"
    fi
elif [ "$os_release" == "ubuntu" ] && [ "$os_maj_ver" == "18.04" ];then
    install_file=$(ls *-execution_*.deb)
    apt install -f -y ./$install_file 
else
    echo "Unsupported Release: $os_release"
fi

sed -i "s/${PBS_SERVER_STRING}/${pbs_server}/g" /etc/pbs.conf
sed -i "s/${PBS_SERVER_STRING}/${pbs_server}/g" /var/spool/pbs/mom_priv/config
sed -i "s/^if /#if /g" /opt/pbs/lib/init.d/limits.pbs_mom
sed -i "s/^fi/#fi /g" /opt/pbs/lib/init.d/limits.pbs_mom
systemctl enable pbs 
systemctl start pbs 

# Retrieve the VMSS name to be used as the pool name for multiple VMSS support
poolName=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmScaleSetName')
if [ -z "$poolName" ]; then
    echo "Unable to query MDS"
    poolName="compute"
fi
echo "Registering node for poolName $poolName"
/opt/pbs/bin/qmgr -c "c n $(hostname) resources_available.pool_name='$poolName'" || exit 1

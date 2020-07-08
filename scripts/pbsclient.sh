#!/bin/bash
set -e

# Check to see if the node is able to access the network
i_cnt=0
wget -q --tries=10 --timeout=20 --spider http://google.com > /dev/null
while [[ $? != 0 ]]
do
        echo "Offline: $i_cnt"
        if [ "$i_cnt" -eq 10 ]
        then
            echo "tried 10 times to no avail. Exiting"
            exit -1
        fi  
        sleep 5
        wget -q --tries=10 --timeout=20 --spider http://google.com > /dev/null
        i_cnt=$((i_cnt+1))

done
echo "Online!!!"

# arg: $1 = pbs_server
pbs_server=$1

if [ "$(rpm -qa pbspro-execution)" = "" ];then
    yum install -y jq
    yum install -y pbspro-execution-19.1.1-0.x86_64.rpm

    sed -i "s/CHANGE_THIS_TO_PBS_PRO_SERVER_HOSTNAME/${pbs_server}/g" /etc/pbs.conf
    sed -i "s/CHANGE_THIS_TO_PBS_PRO_SERVER_HOSTNAME/${pbs_server}/g" /var/spool/pbs/mom_priv/config
    sed -i "s/^if /#if /g" /opt/pbs/lib/init.d/limits.pbs_mom
    sed -i "s/^fi/#fi /g" /opt/pbs/lib/init.d/limits.pbs_mom
    systemctl enable pbs
    systemctl start pbs

    # Retrieve the VMSS name to be used as the pool name for multiple VMSS support
    poolName=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmScaleSetName')
    /opt/pbs/bin/qmgr -c "c n $(hostname) resources_available.pool_name='$poolName'"
    
else
    echo "PBS client was already installed"
fi

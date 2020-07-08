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


admin_user=$(whoami)

if [ "$(rpm -qa pbspro-server)" = "" ];then
    yum install -y pbspro-server-19.1.1-0.x86_64.rpm
    systemctl enable pbs
    systemctl start pbs
    /opt/pbs/bin/qmgr -c "s s managers += ${admin_user}@*"
    /opt/pbs/bin/qmgr -c 's s flatuid=t'
    /opt/pbs/bin/qmgr -c 's s job_history_enable=t'
    /opt/pbs/bin/qmgr -c 'c r pool_name type=string,flag=h'

    # Update the sched_config file to schedule jobs that request pool_name
    sed -i "s/^resources: \"ncpus,/resources: \"ncpus, pool_name,/g" /var/spool/pbs/sched_priv/sched_config
    systemctl restart pbs
else
    echo "PBSPro already installed"
fi

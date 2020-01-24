#!/bin/bash

admin_user=$(whoami)

if [ "$(rpm -qa pbspro-server)" = "" ];then
    sudo yum install -y pbspro-server-19.1.1-0.x86_64.rpm
    sudo systemctl enable pbs
    sudo systemctl start pbs
    sudo /opt/pbs/bin/qmgr -c "s s managers += ${admin_user}@*"
    sudo /opt/pbs/bin/qmgr -c 's s flatuid=t'
    sudo /opt/pbs/bin/qmgr -c 's s job_history_enable=t'
    sudo /opt/pbs/bin/qmgr -c 'c r pool_name type=string,flag=h'

    # Update the sched_config file to schedule jobs that request pool_name
    sudo sed -i "s/^resources: \"ncpus,/resources: \"ncpus, pool_name,/g" /var/spool/pbs/sched_priv/sched_config
    sudo systemctl restart pbs
else
    echo "PBSPro already installed"
fi

#!/bin/bash

admin_user=$(whoami)

sudo yum install -y pbspro-server-19.1.1-0.x86_64.rpm
sudo systemctl enable pbs
sudo systemctl start pbs
sudo /opt/pbs/bin/qmgr -c "s s managers += ${admin_user}@*"
sudo /opt/pbs/bin/qmgr -c 's s flatuid=t'
sudo /opt/pbs/bin/qmgr -c 's s job_history_enable=t'

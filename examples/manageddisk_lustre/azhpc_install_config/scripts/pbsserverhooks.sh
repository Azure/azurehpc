#!/bin/bash
# Add hooks

log_analytics_account=$1
log_analytics_key=$2

cd /tmp
sudo yum install -y git
git clone https://github.com/JonShelley/pbs_hooks.git
cd pbs_hooks/azure


sudo /opt/pbs/bin/qmgr -c 'create hook setup_jobdir'
sudo /opt/pbs/bin/qmgr -c 'set hook setup_jobdir event="execjob_begin,execjob_end"'
sudo /opt/pbs/bin/qmgr -c 'import hook setup_jobdir application/x-python default setup_jobdir.py'

sudo /opt/pbs/bin/qmgr -c 'create hook stop_wa'
sudo /opt/pbs/bin/qmgr -c 'set hook stop_wa event="execjob_begin,execjob_end"'
sudo /opt/pbs/bin/qmgr -c 'import hook stop_wa application/x-python default stop_waagent.py'

sed -i 's/xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/${log_analytics_account}/g' send_app_data_to_log_analytics.json
sed -i 's/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/${log_analytics_key}/g' send_app_data_to_log_analytics.json
sudo /opt/pbs/bin/qmgr -c 'create hook azure_la'
sudo /opt/pbs/bin/qmgr -c 'set hook azure_la event=execjob_epilogue'
sudo /opt/pbs/bin/qmgr -c 'set hook azure_la user=pbsuser'
sudo /opt/pbs/bin/qmgr -c 'import hook azure_la application/x-config default send_app_data_to_log_analytics.json'
sudo /opt/pbs/bin/qmgr -c 'import hook azure_la application/x-python default send_app_data_to_log_analytics.py'

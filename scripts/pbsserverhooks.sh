#!/bin/bash
# Add hooks

cd /tmp
wget https://raw.githubusercontent.com/Azure/azurehpc/master/pbshooks/setup_jobdir.py
sudo /opt/pbs/bin/qmgr -c 'create hook setup_jobdir'
sudo /opt/pbs/bin/qmgr -c 'set hook setup_jobdir event="execjob_begin,execjob_end"'
sudo /opt/pbs/bin/qmgr -c 'import hook setup_jobdir application/x-python default setup_jobdir.py'

wget https://raw.githubusercontent.com/Azure/azurehpc/master/pbshooks/stop_waagent.py
sudo /opt/pbs/bin/qmgr -c 'create hook stop_wa'
sudo /opt/pbs/bin/qmgr -c 'set hook stop_wa event="execjob_begin,execjob_end"'
sudo /opt/pbs/bin/qmgr -c 'import hook stop_wa application/x-python default stop_waagent.py'

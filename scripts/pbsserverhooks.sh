#!/bin/bash
# Add hooks

HOOKS_DIR=~/azhpc_install_config/scripts/pbshooks
sudo /opt/pbs/bin/qmgr -c 'create hook setup_jobdir'
sudo /opt/pbs/bin/qmgr -c 'set hook setup_jobdir event="execjob_begin,execjob_end"'
sudo /opt/pbs/bin/qmgr -c "import hook setup_jobdir application/x-python default $HOOKS_DIR/setup_jobdir.py"

sudo /opt/pbs/bin/qmgr -c 'create hook stop_wa'
sudo /opt/pbs/bin/qmgr -c 'set hook stop_wa event="execjob_begin,execjob_end"'
sudo /opt/pbs/bin/qmgr -c "import hook stop_wa application/x-python default $HOOKS_DIR/stop_waagent.py"

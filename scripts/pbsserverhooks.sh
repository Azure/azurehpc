#!/bin/bash
# Add hooks

HOOKS_DIR=~/azhpc_install_config/scripts/pbshooks

# Install the setup local job directory
sudo /opt/pbs/bin/qmgr -c 'create hook setup_jobdir'
sudo /opt/pbs/bin/qmgr -c 'set hook setup_jobdir event="execjob_begin,execjob_end"'
sudo /opt/pbs/bin/qmgr -c "import hook setup_jobdir application/x-python default $HOOKS_DIR/setup_jobdir.py"

# Install the stop waagent hook
sudo /opt/pbs/bin/qmgr -c 'create hook stop_wa'
sudo /opt/pbs/bin/qmgr -c 'set hook stop_wa event="execjob_begin,execjob_end"'
sudo /opt/pbs/bin/qmgr -c "import hook stop_wa application/x-python default $HOOKS_DIR/stop_waagent.py"

# Install chk_ib test
/opt/pbs/bin/qmgr -c 'create hook chk_ib'
/opt/pbs/bin/qmgr -c 'set hook chk_ib event=exechost_startup'
/opt/pbs/bin/qmgr -c "import hook chk_ib application/x-python default $HOOKS_DIR/chk_ib.py"

# Install user cleaup
/opt/pbs/bin/qmgr -c 'create hook user_cleanup'
/opt/pbs/bin/qmgr -c 'set hook user_cleanup event=execjob_end'
/opt/pbs/bin/qmgr -c "import hook user_cleanup application/x-python default $HOOKS_DIR/pbs_user_cleanup.py"

# Install the stream test
mkdir -p /data/node_utils
cd /data/node_utils
wget "https://azhpcscus.blob.core.windows.net/apps/Stream/stream.tgz"
tar xzvf stream.tgz

sudo /opt/pbs/bin/qmgr -c 'create hook nhc_run_stream'
sudo /opt/pbs/bin/qmgr -c 'set hook nhc_run_stream event="exechost_startup"'
sudo /opt/pbs/bin/qmgr -c "import hook nhc_run_stream application/x-python default $HOOKS_DIR/nhc_run_stream.py"

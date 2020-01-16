# Azure

## Check IB
Purpose:
- To check if the IB on the HPC compute nodes (H/HB/HC) are showing as up

### Required files
- chk_ib.py: Hook to check if eth1 is up IB enabled H16r(m) or NV24r nodes

### Setup Hook
qmgr commands
```
/opt/pbs/bin/qmgr -c "create hook chk_ib"
/opt/pbs/bin/qmgr -c "set hook chk_ib event=exechost_startup"
/opt/pbs/bin/qmgr -c "import hook chk_ib application/x-python default chk_ib.py"
```

## Setup jobdir
Purpose:
- To create a job dir on the local SSD that the user can use on each node assigned to the job

### Required files
- setup_jobdir.py

### Setup Hook
qmgr commands
```
create hook setup_jobdir
set hook setup_jobdir event="execjob_begin,execjob_end"
import hook setup_jobdir application/x-python default setup_jobdir.py
```

## Manage WAAgent
Purpose:
- To reduce jitter on the compute nodes when jobs are running

### Required files
- stop_waagent.py

### Setup Hook
qmgr commands
```
create hook stop_wa
set hook stop_wa event="execjob_begin,execjob_end"
import hook stop_wa application/x-python default stop_waagent.py
```

## Kill any orphan processes on the node for the user running the job
Purpose:
- To delete all of the user processes on the nodes once the job has completed

### Required files
- pbs_user_proc_cleanup.py

### Setup hook
qmgr commands
```
create hook user_cleanup
set hook user_cleanup event="execjob_end"
import hook user_cleanup application/x-python default pbs_user_cleanup.py
```

## Run nhc_run_stream
Purpose:
- To check the memory stream performance of the node when it is boots up

### Required files
- Refer to the pbsserverhooks.sh script

### Setup Hook
```
sudo /opt/pbs/bin/qmgr -c 'create hook nhc_run_stream'
sudo /opt/pbs/bin/qmgr -c 'set hook nhc_run_stream event="exechost_startup"'
sudo /opt/pbs/bin/qmgr -c "import hook nhc_run_stream application/x-python default $HOOKS_DIR/nhc_run_stream.py"
```

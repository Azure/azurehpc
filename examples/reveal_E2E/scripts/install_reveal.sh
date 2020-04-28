#!/bin/bash

REVEAL_SAS_URL=$1
REVEAL_LICENSE_SAS_URL=$2
INSTALL_DIR=$3

REVEAL_BASE_DIR_NAME=reveal-time-4.1-2020-04-12
REVEAL_TAR_GZ=${REVEAL_BASE_DIR_NAME}.tar.gz
REVEAL_LICENCE_FILE=license-demo

cd $INSTALL_DIR

wget -O $REVEAL_TAR_GZ $REVEAL_SAS_URL
tar xvf $REVEAL_TAR_GZ

cat > patch_JobSetupQueueConfig << EOF
--- ${REVEAL_BASE_DIR_NAME}/src/misc/JobSetupQueueConfig.py_orig     2020-03-07 19:16:57.267206718 +0000
+++ ${REVEAL_BASE_DIR_NAME}/src/misc/JobSetupQueueConfig.py  2020-03-07 19:19:01.385074424 +0000
@@ -193,10 +193,10 @@
             elif mode=="mpi_exclusive": self.locals['pbs_resource_list'] = 'nodes=%d,tpn=1,naccesspolicy=singlejob'%nnodes
             elif mode=="mpi_shared"   : self.locals['pbs_resource_list'] = 'nodes=%d,tpn=%d,naccesspolicy=singlejob'%(nnodes*tpn,tpn)
         elif sched=="pbspro":
-            if   mode=="exclusive"    : self.locals['pbs_resource_list'] = 'nodes=1,tpn=1'
-            elif mode=="shared"       : self.locals['pbs_resource_list'] = 'nodes=1'
-            elif mode=="mpi_exclusive": self.locals['pbs_resource_list'] = 'nodes=%d,tpn=1'%nnodes
-            elif mode=="mpi_shared"   : self.locals['pbs_resource_list'] = 'nodes=%d,tpn=%d'%(nnodes*tpn,tpn)
+            if   mode=="exclusive"    : self.locals['pbs_resource_list'] = 'select=1:ncpus=1:mpiprocs=1'
+            elif mode=="shared"       : self.locals['pbs_resource_list'] = 'select=1'
+            elif mode=="mpi_exclusive": self.locals['pbs_resource_list'] = 'select=%d:ncpus=1:mpiprocs=1,place=scatter:excl'%nnodes
+            elif mode=="mpi_shared"   : self.locals['pbs_resource_list'] = 'select=%d:ncpus=%d:mpiprocs=%d,place=scatter:excl'%(nnodes,tpn,tpn)
         elif sched=="slurm":
             if   mode=="exclusive"    : self.locals['pbs_resource_list'] = '--nodes=%d --ntasks-per-node=%d'%(1     ,1  )
             elif mode=="shared"       : self.locals['pbs_resource_list'] = '--nodes=%d'                     %(1         )
EOF

cat > patch_queue_job_script_template << EOF
--- ${REVEAL_BASE_DIR_NAME}/src/bin/queue_job_script_template.py_orig        2020-04-16 23:34:33.271217014 +0000
+++ ${REVEAL_BASE_DIR_NAME}/src/bin/queue_job_script_template.py     2020-04-16 20:49:14.268625772 +0000
@@ -66,7 +66,7 @@
     elif sched == 'lsf'   : replicanum = int(os.environ["LSB_JOBINDEX"       ])
     elif sched == 'uge'   : replicanum = int(os.environ["SGE_TASK_ID"        ])
     elif sched == 'archer': replicanum = int(os.environ["PBS_ARRAY_INDEX"    ])
-    else                  : replicanum = int(os.environ["PBS_ARRAYID"        ])
+    else                  : replicanum = int(os.environ["PBS_ARRAY_INDEX"        ])
     repl_rng_cnts = xxxx_repl_rng_cnts
     for rng in repl_rng_cnts:
         if   replicanum> rng[0]+rng[1]-1: jobid += rng[1]
EOF

cat > opencps_install.prefs << EOF
{
"com.ogi.opencps.closed_projects" : [],
"disable_pbs_out_err" : false,
"pbs_sched" : "pbspro",
"com.ogi.opencps.mpi_protocol" : "ib",
"use_pbs_array_jobs" : true,
"scratch" : [ "/mnt/resource" ]
}
EOF

sudo yum install -y patch

patch  -p0 < patch_JobSetupQueueConfig
patch  -p0 < patch_queue_job_script_template 

cp opencps_install.prefs $REVEAL_BASE_DIR_NAME/src/misc

cd $REVEAL_BASE_DIR_NAME
wget -O $REVEAL_LICENCE_FILE $REVEAL_LICENSE_SAS_URL


# Node health check integrated with CycleCloud SLURM 

It is important to run healthchecks on Specialty SKU's (like NDv4(A100)) to identify unhealthy VM's and make sure they are not included in job (for example 
by marking the node and putting it into a drain state). Here we give an example of leveraging the built-in healthcheck hooks in SLURM and using them to run the
LBNL Node Health check framework (https://github.com/mej/nhc). Some specific healthchecks have been written for ND96asr_v4 (40GB A100) and a Cyclecloud project
is created to allow this healthcheck framework to be integrated in CycleCloud SLURM. This has been tested on CycleCloud 8.2.2, SLURM 2.6.4 and ubuntu-hpc 18.04 marketplace image.

## Prerequisites

- CycleCloud 8.2.2 is installed, Ubuntu 18.04, SLURM 2.6.4 (Tested with these versions, other versions may work)
- Compute node(s), ND96asr_v4 or ND96amsr_v4 (Running Ubuntu-hpc 18.04), or HBv3 running CentOS-HPC 7.7

## Design
The Node health checks only run on IDLE SLURM nodes (not on nodes with running jobs). If a node healthcheck fails, the node will be put into a DRAIN state (All jobs using this node will be allowed to complete, but not new jobs will use this node). If the issue that caused the healthcheck to fail is resolved, the net time the node health check is run the node will be move from the DRAIN state to the IDLE state, and will now be ready to accept new jobs. This example contains an example node check for ND96amsr_v4 (nd96amsr_v4.conf) and HBv3, it should be relatively easy to create similar configuration files for other specialty SKU's like HBv2 and HC, and run health checks for those SKU's also using this framework.

## What health checks are performed?

The nd96asr_v4.conf and nd96amsr_v4.conf nhc configuration file specifies what health checks to perform on ND96asr_v4 (or ND96amsr_v4), which includes

* Check all mounted filesystems (including shared filesystems and local NVMe SSD)
* Check if filesystems are nearly full (OS disk and shared filesystems)
* Check all IB interfaces
* Check ethernet interfaces
* Check for large loads
* GPU, check GPU persistence mode, if disabled then attempt to enable it
* GPU, Nvidia Data Center GPU Monitor diag -r 2 (medium test)
* GPU, Cuda bandwidth tests (dtoh and htod)
* GPU, Basic GPU checks like lost GPU
* GPU, Check application GPU clock frequencies
* GPU, Check GPU ECC errors
* Check IB bandwidth performance
* Check NCCL allreduce IB loopback bandwidth performance
* Check for IB link flapping
* Check for GPU clock throttling
* Check if should drop CPU cached memory
* Check for specific GPU Xid errors
* Run single node NCCL all-reduce test

Will continue to add additional tests.

>Note: Edit configur_nhc.sh (NHC_CONF_FILE_NEW) to specify which nhc configuration file you want to use. 

## Deployment Procedure

Upload the cc_slurm_nhc to your cyclecloud storage locker.
```
cyclecloud project upload <locker>
```

Edit Cluster configuration in portal (or using a cluster json parameter file), to add this spec to your cluster (i.e add cluster-init project to your scheduler and compute nodes) See in the CC Portal Edit-->Advanced-Settings, under Software.

>Note: In my case I am disabling autoscaling (SuspendTime=-1), if you have autoscaling enabled you may need to modify these scripts to prevent the 
DRAINED node from deallocating (i.e enable keep alive)

## key file locations
```
/etc/nhc/nhc.conf   - NHC configuration files (i.e what tests do you want to run)
/etc/default/nhc    - Global parameters
/var/log/nhc.log    - log file for NHC tests.
```

## Adding additional health checks to NHC framework

You can add your own health checks to the NHC framework. An example is azure_cuda_bandwidth.nhc, which is a CUDA bandwidthtest health check specifically for GPU's.
You just add your custom health check to /etc/nhc/scripts and modify your nhc.conf file to use it (/etc/nhc/nhc.conf).

## Kill NHC via SLURM Prolog
To prevent NHC from running while a job is running, we have provided a script to kill NHC processes (kill_nhc.sh). You can run this script before a job starts by using the SLURM PROLOG, set NHC_PROLOG=1 in the configure_nhc.sh script to enable this prolog (default) or set it to 0 to disable it.

>Note: If you have autoscaling enabled, then set AUTOSCALING=1 in the configure_nhc.sh script, this will replace kill_nhc.sh with wait_for_nhc.sh in the prolog.sh (To allow the NHC checks to complete (by waiting) when a node is autoscaled before starting your job)


## Run NHC via SLURM Epilog
If you need to run NHC checks after a job completes (SLURM Epilog), then set NHC_EPILOG=1 in the configure_nhc.sh script.

>Note: If you run NHC via Epilog, then set HealthCheckInterval to a large value so it effectively only runs when a new node is provisioned in the cluster.


## Additional info

The script create_nhc_src_tar.sh is included to create a tarball of the NHC github repository that you can then use when you deploy NHC using the cyclecloud cluster-init project.
If you want to use the created tarball in your cluster-init project then edit cc_slurm_nhc/specs/default/cluster-init/files

```
TAR_FILE=$CYCLECLOUD_SPEC_PATH/files/lbnl-nhc-<DATE>.tar.gz
```
>Note: By default NHC is installed via git clone. If you want to use the tarball instead make sure you copy the tarball to cc_slurm_nhc/specs/default/cluster-init/files

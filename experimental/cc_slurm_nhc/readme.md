# Node health check integrated with CycleCloud SLURM 

It is important to run healthchecks on Specialty SKU's (like NDv4(A100)) to identify unhealthy VM's and make sure they are not included in job (by for example 
by marking the node and putting  into a drain state). Here we give an example of leveraging the built-in healthcheck hooks in SLURM and using them to run the
LBNL Node Health check framework (https://github.com/mej/nhc). Some specific healthchecks have been written for ND96asr_v4 (40GB A100) and a Cyclecloud project
is created to allow this healthcheck framework to be integrated in CycleCloud SLURM. This has been tested on CycleCloud 8.2.1, SLURM 2.5.0 and ubuntu-hpc 18.04 marketplace image.

## Prerequisites

- CycleCloud 8.2.1 is installed, Ubuntu 18.04, SLURM 2.5.0
- Compute node(s), ND96asr_v4 (Running Ubuntu-hpc 18.04)

## Design
The Node health checks only run on IDLE SLURM nodes (not on nodes with running jobs). If a node healthcheck fails, the node will be put into a DRAIN state (All jobs using this node will be allowed to complete, but not new jobs will use this node). If the issue that caused the healthcheck to fail is resolved, the net time the node health check is run the node will be move from the DRAIN state to the IDLE state, and will now be ready to accept new jobs. This example contains an example node check for ND96asr_v4 (nd96asr_v4.conf), it should be relatively easy to create similar configuration files for other specialty SKU's like HBv3,HBv2 and HC, and run health checks for those SKU's also using this framework.

## Deployment Procedure

Upload the cc_slurm_nhc to your cyclecloud storage locker.
```
cyclecloud project upload <locker>
```

Edit Cluster configuration in portal (or using a clustr json parameter file), to add this spec to your cluster (i.e add cluster-init project to your compute nodes)
See in the CC Portal Edit-->Advanced-Settings, under Software. Also, added the following to the Additional Slurm config section.

```
SuspendExcParts=hpc
HealthCheckProgram=/usr/sbin/nhc
HealthCheckInterval=300
HealthCheckNodeState=IDLE
```
>Note: In my case I am disabling autoscaling (SuspendExcParts=hpc), if you have autoscaling enabled you may need to modify these scripts to prevent the 
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

## Additional info

The script create_nhc_src_tar.sh is included to create a tarball of the NHC github repository that you can then use when you deploy NHC using the cyclecloud cluster-init project.
If you want to use the created tarball in your cluster-init project then edit cc_slurm_nhc/specs/default/cluster-init/files

```
TAR_FILE=$CYCLECLOUD_SPEC_PATH/files/lbnl-nhc-<DATE>.tar.gz
```
>Note: By default NHC is installed via git clone. If you want to use the tarball instead make sure you copy the tarball to cc_slurm_nhc/specs/default/cluster-init/files

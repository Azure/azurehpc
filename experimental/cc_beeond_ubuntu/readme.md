# Deploy BeeOND with CycleCloud (Ubuntu-hpc) 

Contains a cyclecloud project that will deploy BeeOND parallel filesystem on compute nodes running Ubuntu-hpc marketplace image.
Tested on NDv4 running ubuntu-hpc 18.04.

## Prerequisites

- CycleCloud 8.2.1 is installed, Ubuntu 18.04, SLURM 2.5.0, BeeGFS/BeeOND 7.2.5
- Compute node(s), ND96asr_v4 (Running Ubuntu-hpc 18.04)


## Deployment Procedure

Upload the cc_beeond_ubuntu to your cyclecloud storage locker.
```
cyclecloud project upload <locker>
```

Edit Cluster configuration in portal (or using a cluster json parameter file), to add this spec to your cluster (i.e add cluster-init project to your compute nodes) See in the CC Portal Edit-->Advanced-Settings, under Software.


## Start and Stop the BeeOND parallel filesystem

To start the BeeOND 
```
beeond start -P -n <hostfile> -d <local_ssd_mount_point> -c <BeeOND_mount_point>
```
To check BeeOND is mounted (assuming BeeOND_mount_point=/beeond)
```
df -h
```

To stop the BeeOND PFS
```
beeond stop -P -n <hostfile> -d <local_ssd_mount_point> -c <BeeOND_mount_point>
```

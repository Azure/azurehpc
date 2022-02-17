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
To check BeeOND is mounted (assuming BeeOND_mount_point=/beeond, in this case a 2 node NDv4 creates a 14TB /beeond PFS)
```
df -h
Filesystem         Size  Used Avail Use% Mounted on
udev               443G     0  443G   0% /dev
tmpfs               89G   18M   89G   1% /run
/dev/sda1           58G   19G   40G  32% /
tmpfs              443G     0  443G   0% /dev/shm
tmpfs              5.0M     0  5.0M   0% /run/lock
tmpfs              443G     0  443G   0% /sys/fs/cgroup
/dev/sda15         105M  4.4M  100M   5% /boot/efi
/dev/sdb1          2.8T   90M  2.7T   1% /mnt
/dev/md128         7.0T  7.2G  7.0T   1% /mnt/resource_nvme
tmpfs               89G     0   89G   0% /run/user/20001
beegfs_ondemand     14T   15G   14T   1% /beeond
```

To stop the BeeOND PFS
```
beeond stop -P -n <hostfile> -d <local_ssd_mount_point> -c <BeeOND_mount_point>
```

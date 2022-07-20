# pyxis/enroot contrainer support integrated with CycleCloud SLURM 

Container support can be integrated with SLURM using Nvidia's pyxis/enroot implementation. A cyclecloud project is provided to allow it easily uploaded to a cyclecloud 
locker so it can be easily installed via cyclecloud cloud-init mechanism.

## Prerequisites

- CycleCloud 8.2.2 is installed, Ubuntu 18.04, SLURM 2.6.4 (Tested with these versions, other versions may work)
- Compute node(s), ND96asr_v4 or ND96amsr_v4 (Running Ubuntu-hpc 18.04)

## Deployment Procedure

Upload the cc_slurm_pycis_enrrot to your cyclecloud storage locker.
```
cyclecloud project upload <locker>
```

Edit Cluster configuration in portal (or using a cluster json parameter file), to add this spec to your cluster (i.e add cluster-init project to your scheduler and compute nodes).
See in the CC Portal Edit-->Advanced-Settings, under Software.


## Cadence Clarity 3D Solver

Cadence® Clarity™ 3D Solver is a 3D electromagnetic (EM) simulation software tool for designing critical interconnects for PCBs, IC packages, and system on IC (SoIC) designs. The Clarity 3D Solver lets you tackle complex electromagnetic (EM) challenges when designing systems for 5G, automotive, high-performance computing (HPC), and machine learning applications with gold-standard accuracy.

[Cadence Clarity 3D Solver Home Page](https://www.cadence.com/ko_KR/home/tools/system-analysis/em-solver/clarity-3d-solver.html)

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. The [simple_hpc_pbs](https://github.com/Azure/azurehpc/tree/eda/examples/simple_hpc_pbs) template in the examples directory is a suitable choice.

After cluster is built, first copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

Then connect to the headnode:
```
azhpc-connect -u hpcuser headnode
```

## Installation

Change folder to:
```
cd /azurehpc/apps/cadence_clarity3d
```

Take a look at the 'build_clarity3d.sh' script, modify the installation directory if needed:
```
vim build_clarity3d.sh
```

Run the 'build_clarity3d.sh' script:
```
source build_clarity3d.sh
```
## Configure License Server
Make necessary modification of the license file you received from Cadence or supplier. EX: modify the SERVER name:
```
...
########################### LICENSE KEYS START HERE ######################
SERVER Cadence_SERVER 000d3a5f9947 5280
DAEMON cdslmd ./cdslmd
# DO NOT REMOVE THE USE_SERVER LINE
USE_SERVER
...
```
Copy the license file to the VM (EX: headnode), and then execute:
```
[your installation directory]/bin/lmgrd -c License_46499_000d3a5f9947_7_2_2020.txt -l license.log
```

## Run Tempus
Run your Clarity 3D simulation on the cluster.

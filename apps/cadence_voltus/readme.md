## Cadence® Voltus™ IC Power Integrity Solutio

The Cadence® Voltus™ IC Power Integrity Solution is a standalone, cloud-ready, full-chip, cell-level power signoff tool. The Voltus tool is of particular value to designers by providing better understanding of the power grid strength, as well as debugging, verifying, and fixing IC chip power consumption, IR drop, and electromigration (EM) constraints and violations (EM-IR).

[Cadence Voltus IC Power Integrity Solutionr Home Page](https://www.cadence.com/zh_TW/home/tools/digital-design-and-signoff/silicon-signoff/voltus-ic-power-integrity-solution.html)

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
cd /azurehpc/apps/cadence_voltus
```

Take a look at the 'build_voltus.sh' script, modify the installation directory if needed:
```
vim build_voltus.sh
```

Run the 'build_voltus.sh' script:
```
source build_voltus.sh
```
## Configure License Server
Make necessary modification of the license file you received from Cadence or supplier. EX: modify the SERVER name:
```
...
########################### LICENSE KEYS START HERE ######################
SERVER Cadence_SERVER 00ad3a9ddd47 5280
DAEMON cdslmd ./cdslmd
# DO NOT REMOVE THE USE_SERVER LINE
USE_SERVER
...
```
Copy the license file to the VM (EX: headnode), and then execute:
```
[your installation directory]/bin/lmgrd -c <YOUR LICENCE FILENAME> -l license.log
```

## Run Voltus
Run your Voltus simulation on the cluster.

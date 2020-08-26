## Cadence Tempus

The Cadence® Tempus™ Timing Signoff Solution is the static timing analysis (STA) tool for FinFET designs. The Tempus solution is designed to tackle the most advanced timing requirements including full signal integrity (SI) analysis, glitch analysis and propagation, statistical on-chip variation (SOCV), multi-mode and multi-corner (MMMC) analysis, static and dynamic power reduction, and hierarchical timing models.

[Cadence Tempus Home Page](https://www.cadence.com/en_US/home/tools/digital-design-and-signoff/silicon-signoff/tempus-timing-signoff-solution.html)

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
cd /azurehpc/apps/cadence_tempus
```

Take a look at the 'build_tempus.sh' script, modify the installation directory if needed:
```
vim build_tempus.sh
```

Run the 'build_tempus.sh' script:
```
source build_tempus.sh
```
Necessary Tempus packages will be installed, for example:
```
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
You are able to run your Tempus simulation on the cluster. See *smote_test.sh* for example.
Below a sample result from *monitor_host.log*:
```
Status keys: E excellent, G good, B bad, T terrible.
Memory values:
  total = Real memory of host
  progs = Real memory used by processes, including swappable cache
  used =  Real memory used by processes, excluding swappable cache
Started at: 20/04/02 06:35:58
edaheadnode(0)    TMPDIR is : /tmp/ssv_tmpdir_16886_kBPJJ2
edaheadnode(1)    TMPDIR is : /tmp/ssv_tmpdir_16998_q3wRi6
edaheadnode(2)    TMPDIR is : /tmp/ssv_tmpdir_17008_S4dwPb
edaheadnode(3)    TMPDIR is : /tmp/ssv_tmpdir_17018_QGV719

===============  ========  ========================  ========================
Host             CPU         Memory (GB)             TMPDIR (GB)      (Mb/s)
name(id)         util %    total progs used  %used   total    avail    rate
===============  ========  ===== ===== ===== ======  ========================
06:35:58
edaheadnode(0)        4 E    346    21     6    1 E   29.50     0.61 E  N/A
edaheadnode(1)        4 E    346    21     6    1 E   29.50     0.61 E   15 T
edaheadnode(2)        4 E    346    21     6    1 E   29.50     0.61 E   10 T
edaheadnode(3)        4 E    346    21     6    1 E   29.50     0.61 E   10 T
06:36:58
edaheadnode(0)        5 E    346    24     9    2 E   29.50     0.38 G   34 T
edaheadnode(1)        5 E    346    24     9    2 E   29.50     0.38 G   15 T
edaheadnode(2)        5 E    346    24     9    2 E   29.50     0.38 G   10 T
edaheadnode(3)        5 E    346    24     9    2 E   29.50     0.38 G   10 T
```

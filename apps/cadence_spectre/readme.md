## Cadence Spectre X

The Cadence® Spectre® X Simulator  performs advanced SPICE-accurate simulation, enables you to solve large-scale verification simulation challenges for complex analog, RF, and mixed-signal blocks and subsystems. In addition, the Spectre X Simulator allows you to massively distribute simulation workloads, enabling greater speed and capacity.
[Cadence Spectre Home Page](https://www.cadence.com/ko_KR/home/tools/custom-ic-analog-rf-design/circuit-simulation/spectre-x-simulator.html)

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
cd /azurehpc/apps/cadence_spectre
```

Take a look at the 'build_spectre.sh' script, modify the installation directory if needed:
```
vim build_spectre.sh
```

Run the 'build_spectre.sh' script:
```
source build_spectre.sh
```
The script will do TWO things, first to install install necessary Spectre X packages, for example:
```
    10020:Legato (TM) Reliability Solution
    32501:Spectre(R) Model Interface Option
    33580:Spectre(R) RelXpert
    3500:Spectre Characterization Simulator Option
    38500:Spectre(R) Classic Simulator
    38510:Spectre Advanced Simulation Interface Option to Spectre Simulator - L
    38520:Spectre(R)-RF Option for 38500 and 91050
    38530:Interactive mode for Spectre(R) using Python/TCL Limited Access
    90003:Spectre Multi-mode Simulation with AP Simulator
    90004:Spectre(R) Multi-mode Simulation
    90005:Spectre(R) Multi-Mode Simulation with AMS
    90006:MMSIM with Spectre X simulator and Spectre X CPU Acceleration
    91010:Spectre(R) APS Verification
    91050:Spectre(R) Accelerated Parallel Simulator
    91051:Spectre Fault Analysis option to Virtuoso Accelerated Parallel Simulator (91050)
    91055:Spectre(R) X Simulator
    91400:Spectre(R) Power Option
    91500:Spectre(R) CPU Accelerator Option
    91600:Spectre Extensive Partitioned Simulator
    91700:Spectre Electromigration and IR Drop Simulator - 3 pack
```
Secondly to download ready-to-use examples under *spectre_example* directory.
```
[hpcadmin@headnode spectre_example]$ pwd
/data/spectrex/spectre_example
[hpcadmin@headnode spectre_example]$ ls -l
total 24
-rwxr-xr-x.  1 hpcadmin hpcadmin  581 May  5 02:21 CLEAN
drwxr-x---. 54 hpcadmin hpcadmin 4096 May  5 02:21 amsPLL
-rwxr-x---.  1 root     root      386 May  5 02:21 cds.lib
-rw-r--r--.  1 hpcadmin hpcadmin  711 May  5 02:21 cshrc_spectre
drwxr-xr-x. 49 hpcadmin hpcadmin 4096 May  5 02:20 gpdk090
drwxr-x---.  3 hpcadmin hpcadmin   21 May  5 02:21 models
drwxr-xr-x.  3 hpcadmin hpcadmin   21 May  5 02:20 models_gpdk045
drwxr-xr-x.  6 hpcadmin hpcadmin 4096 Aug 20 23:50 postlayout_dspf
drwxr-xr-x.  2 hpcadmin hpcadmin   74 May  5 02:20 postlayout_flat
drwxr-xr-x.  4 hpcadmin hpcadmin  120 May  5 02:20 prelayout
drwxr-xr-x.  2 hpcadmin hpcadmin   23 May  5 02:20 standalone
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

## Run Spectre X
You can now run a Spectre X job on the cluster. Below is an example to run a post layout dspf simulation with 32 threads (*-mt=32*):
```
[hpcadmin@headnode postlayout_dspf]$ cat run.spectrex
#!/bin/bash

# TODO: Change to your installation directory
export MMSIMHOME="/data/spectrex/"

export PATH="$PATH:$MMSIMHOME/tools/bin:$MMSIMHOME/tools/spectre/bin:$MMSIMHOME/tools/ultrasim/bin:$MMSIMHOME/tools/relxpert/bin"

export LD_LIBRARY_PATH="/usr/lib/X11:/usr/X11R6/lib:/usr/lib:/usr/dt/lib/usr/openwin/lib:/usr/ucblib"

export LM_LICENSE_FILE="5280@headnode"
export CDS_LIC_FILE="$LM_LICENSE_FILE"

export CDS_AUTO_64BIT="ALL"

cd /data/spectrex/spectre_example/postlayout_dspf
sudo yum -y install ksh
spectre -64 +preset=cx +mt=32 input.scs -o SPECTREX_cx_32t +lqt 0 -f sst2

```
Sample result:

![alt text](https://edarg3diag.blob.core.windows.net/edatools/Cadence/spectre%20screenshot.png "Spectre X result")

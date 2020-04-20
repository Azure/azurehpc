## Install and run Cadence Tempus

The Cadence® Tempus™ Timing Signoff Solution is the static timing analysis (STA) tool in the Semiconductor industry. Tempus solution is designed to tackle the most advanced timing requirements including full signal integrity (SI) analysis, statistical variation (SOCV), multi-mode and multi-corner analysis, static and dynamic power, and glitch.

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Recommended that you start with the cfd_workflow tutorial for the cluster setup since you need extra disk space for the install and running of the benchmarks.

Dependencies for binary version:

* None

## Installation

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

### Install Prerequisite Packages, Cadence SSV_191 and Tempus_171

Note 1: Please ensure you have at least 300GB free space in your storage. You can run below command to verify:
```
df -h
```
Note 2: You can modify your installation directory in the scripts. (Default is /datadrive) 

```
azhpc-run -u hpcuser -n "headnode compute" ~/apps/cadence_tempus/build_tempus.sh
```
Note 3: There is no need to have license to install the Tempus tools.

### Create SWAP File
For Tempus, it is required to have at least 4GB size of SWAP File, and the 'checkSysConf' util will check if it meets the requirement.

1. To create a swap file, update the /etc/waagent.conf file by setting the following three parameters:
```
ResourceDisk.Format=y
ResourceDisk.EnableSwap=y
ResourceDisk.SwapSizeMB=xx
```
Note: The xx placeholder represents the desired number of megabytes (MB) for the swap file. For example: 8096.

2. Restart the WALinuxAgent service by running one of the following commands, depending on your OS.
Ubuntu: 
```
service walinuxagent restart
```
Red Hat/Centos: 
```
service waagent restart
```
3. Run the following commands to show the new swap apace that's being used after the restart:
```
swapon -s
```
4. If the swap file isn't created, you can restart the virtual machine.

### Config License

Note: You will need the license in order to run the tool. You can either purchase or contact Cadence representatives for evaluation license. https://support.cadence.com/

1. Copy your license file to the headnode: 
```
azhpc-scp -u hpcuser -r <your license filename> hpcuser@headnode:.
```
2. Edit the license file with correct HostID and NIC ID/MacAddress as instructed.

Below the example:
```
.
.
#######################################################################
#     INSTRUCTIONS
#######################################################################
#  1. Please   replace  "Cadence_SERVER"  with  hostname  of your machine
#     in line   "SERVER Cadence_SERVER  &lt;hostid&gt; 5280".
#  2. Please replace the relative path(  eg. ./cdslmd   ) to absolute path
#     in the DAEMON line(s).
#  3. Cadence now ships a complete license file for each server, so combining
#     license files with a VENDOR_STRING value other than DEMO is no longer
#     permitted.  Please contact your field administrator if you believe that
#     product licenses are missing from this file.
#  4. Some  e-mail utilities ( commonly on PC or  Macintosh  systems ) may
#     modify the text of an e-mailed license file,   changes such as  word
#     or line wrapping or  subdivision into  multiple sections,  when they
#     receive or forward this file.  The resulting keys will be unreadable
#     by the software security.To avoid this, these changes must be undone
#     or the e-mail utility options disabled.
########################### LICENSE KEYS START HERE ######################
SERVER Cadence_SERVER 000d3a6d1234 5280
.
.
```
3. Config the license server:
Edit the config_license.sh and replace <your license filename> with your license file name.
```
azhpc-run -u hpcuser -n headnode ~/apps/cadence_tempus/config_license.sh <your license filename>
```

Example:
```
azhpc-run -u hpcuser -n headnode ~/apps/cadence_tempus/config_license.sh License_92052_000d3a5e3467_3_29_2020.txt
```

## Connect To Headnode

```
azhpc-connect -u hpcuser headnode
```

## Run Smoke Test
```
smoketest.sh
```

After the smoke run, several log files will be generated under /datadrive/work/Tempus171_RAK/block_scope/work. 
Below the example of monitor_host.log file:

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

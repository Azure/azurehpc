# HPC Application process/thread mapping/pinning checking tool

Correct mapping/pinning of HPC Application processes/threads is critical for optimal performance.
The HPC Application process/thread mapping/pinning checking tool allows you to quickly verify that the processes/threads associated with your HPC Application are mapped/pinned correctly/optimally. This tool shows you the virtual machine NUMA topology (i.e location of code id's, GPU's and NUMA domains), where the processes/threads associated with your HPC Application are mapped/pinned and warnings if they are not mapped/pinned optimally.

## Prerequisites

- python3 is installed
- hwloc package is installed

## Usage
```
 ./check_app_pinning.py -h
usage: check_app_pinning.py [-h] application_pattern

positional arguments:
  application_pattern  Select the application pattern to check [string]

optional arguments:
  -h, --help           show this help message and exit
```
## Example
You have a hybrid parallel application (called hpcapp) running on multiple virtual machines (HB120_v2). You would like to check if the processes and threads are pinned correctly. On one of the virtual machine you run
```
check_app_pinning.py hpcapp

Virtual Machine (cghb120v2) Numa topology

NumaNode id  Core ids              GPU ids
============ ==================== ==========
0            ['0-3']              []
1            ['4-7']              []
2            ['8-11']             []
3            ['12-15']            []
4            ['16-19']            []
5            ['20-23']            []
6            ['24-27']            []
7            ['28-31']            []
8            ['32-35']            []
9            ['36-39']            []
10           ['40-43']            []
11           ['44-47']            []
12           ['48-51']            []
13           ['52-55']            []
14           ['56-59']            []
15           ['60-63']            []
16           ['64-67']            []
17           ['68-71']            []
18           ['72-75']            []
19           ['76-79']            []
20           ['80-83']            []
21           ['84-87']            []
22           ['88-91']            []
23           ['92-95']            []
24           ['96-99']            []
25           ['100-103']          []
26           ['104-107']          []
27           ['108-111']          []
28           ['112-115']          []
29           ['116-119']          []


Application (hpcapp) Mapping/pinning

PID          Threads           Running Threads   Core id mapping   Numa Node ids   GPU ids
============ ================= ================= ================= =============== ===============
13405        7                 4                 0                 [0]             []
13406        7                 4                 4                 [1]             []
13407        7                 4                 8                 [2]             []
13408        7                 4                 12                [3]             []


Warning: 4 threads are mapped to 1 core(s), for pid (13405)
Warning: 4 threads are mapped to 1 core(s), for pid (13406)
Warning: 4 threads are mapped to 1 core(s), for pid (13407)
Warning: 4 threads are mapped to 1 core(s), for pid (13408)
```

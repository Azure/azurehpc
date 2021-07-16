# HPC Application process/thread mapping/pinning checking tool

Correct mapping/pinning of HPC Application processes/threads is critical for optimal performance.
The HPC Application process/thread mapping/pinning checking tool has two main features, it allows you to quickly verify that the processes/threads associated with your HPC Application are mapped/pinned correctly/optimally or it can generate the MPI process/thread pinning syntax for OpenMPI/HPCX and Intel MPI (Currently for HPC VM's based on AMD processors (HB (v1,v2 & v3) and NDv4). This tool shows you the virtual machine NUMA topology (i.e location of code id's, GPU's and NUMA domains), where the processes/threads associated with your HPC Application are mapped/pinned and warnings if they are not mapped/pinned optimally.

## Prerequisites

- python3 is installed
- hwloc package is installed

## Usage
```
 ./check_app_pinning.py -h
usage: check_app_pinning.py [-h] [-anp APPLICATION_PATTERN] [-ppa]
                            [-tnp TOTAL_NUMBER_PROCESSES]
                            [-ntpp NUMBER_THREADS_PER_PROCESS]
                            [-mt {openmpi,intel}]

optional arguments:
  -h, --help            show this help message and exit
  -anp APPLICATION_PATTERN, --application_name_pattern APPLICATION_PATTERN
                        Select the application pattern to check [string]
                        (default: None)
  -ppa, --print_pinning_syntax
                        Print MPI pinning syntax (default: False)
  -tnp TOTAL_NUMBER_PROCESSES, --total_number_processes TOTAL_NUMBER_PROCESSES
                        Total number of MPI processes (used with -ppa)
                        (default: None)
  -ntpp NUMBER_THREADS_PER_PROCESS, --number_threads_per_process NUMBER_THREADS_PER_PROCESS
                        Number of threads per process (used with -ppa)
                        (default: None)
  -mt {openmpi,intel}, --mpi_type {openmpi,intel}
                        Select which type of MPI to generate pinning syntax
                        (used with -ppa) (default: None)
```
## Examples
You are on a Standard_HB120-64rs_v2 virtual machine, you would like to know the correct HPCX pinning syntax to pin 16 MPI
processes and 4 threads per process.

```
check_app_pinning.py -ppa -tnp 16 -ntpp 4

Virtual Machine (Standard_HB120-64rs_v3, cghb64v3) Numa topology

NumaNode id  Core ids              GPU ids
============ ==================== ==========
0            ['0-15']             []
1            ['16-31']            []
2            ['32-47']            []
3            ['48-63']            []

L3Cache id   Core ids
============ ====================
0            ['0-3']
1            ['4-7']
2            ['8-11']
3            ['12-15']
4            ['16-19']
5            ['20-23']
6            ['24-27']
7            ['28-31']
8            ['32-35']
9            ['36-39']
10           ['40-43']
11           ['44-47']
12           ['48-51']
13           ['52-55']
14           ['56-59']
15           ['60-63']


Process/thread openmpi MPI Mapping/pinning syntax for 16 processes and 4 threads per process

--map-by ppr:4:numa:pe=4
```

Note: Incorrect number of processes and threads is flagged with warnings


You have a hybrid parallel application (called hpcapp) running on multiple virtual machines (HB120_v2). You would like to check if the processes and threads are pinned correctly. On one of the virtual machine you run
```
check_app_pinning.py -anp hpcapp

Virtual Machine (Standard_HB120_v2, cghb120v2) Numa topology

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

PID          Threads           Running Threads   Last core id     Core id mapping   Numa Node ids   GPU ids
============ ================= ================= ==============  ================= =============== ===============
13405        7                 4                   0              0                 [0]             []
13406        7                 4                   4              4                 [1]             []
13407        7                 4                   8              8                 [2]             []
13408        7                 4                   12             12                [3]             []


Warning: 4 threads are mapped to 1 core(s), for pid (13405)
Warning: 4 threads are mapped to 1 core(s), for pid (13406)
Warning: 4 threads are mapped to 1 core(s), for pid (13407)
Warning: 4 threads are mapped to 1 core(s), for pid (13408)
```
You then test running the same HPC application on multiple ND96asr_v4 virtual machines.

```
./check_app_pinning.py hello

Virtual Machine (cgndv4) Numa topology

NumaNode id  Core ids              GPU ids
============ ==================== ==========
0            ['0-23']             [3, 2]
1            ['24-47']            [1, 0]
2            ['48-71']            [7, 6]
3            ['72-95']            [5, 4]


Application (hello) Mapping/pinning

PID          Threads           Running Threads   Last core id    Core id mapping   Numa Node ids   GPU ids
============ ================= ================= ==============  ================= =============== ===============
32473        6                 0                 0                  0                 [0]             [3, 2]
32474        6                 2                 24                 24                [1]             [1, 0]
32475        6                 2                 48                 48                [2]             [7, 6]
32476        6                 2                 72                 72                [3]             [5, 4]


Warning: 2 threads are mapped to 1 core(s), for pid (32474)
Warning: 2 threads are mapped to 1 core(s), for pid (32475)
Warning: 2 threads are mapped to 1 core(s), for pid (32476)
Warning: Virtual Machine has 8 GPU's, but only 6 threads are running


For HB_v3 will also show the L3cache topology.

[azureuser@cghb120v3 ~]$ ./check_app_pinning_new.py hello

Virtual Machine (Standard_HB120rs_v3) Numa topology

NumaNode id  Core ids              GPU ids
============ ==================== ==========
0            ['0-29']             []
1            ['30-59']            []
2            ['60-89']            []
3            ['90-119']           []

L3Cache id   Core ids
============ ====================
0            ['0-7']
1            ['8-15']
2            ['16-23']
3            ['24-29']
4            ['30-37']
5            ['38-45']
6            ['46-53']
7            ['54-59']
8            ['60-67']
9            ['68-75']
10           ['76-83']
11           ['84-89']
12           ['90-97']
13           ['98-105']
14           ['106-113']
15           ['114-119']


Application (hello) Mapping/pinning

PID          Threads           Running Threads   Last core id    Core id mapping   Numa Node ids   GPU ids
============ ================= ================= =============== ================= =============== ===============
11588        7                 4                 12              0-29              [0]             []
11589        7                 4                 31              30-59             [1]             []
11590        7                 4                 62              60-89             [2]             []
11591        7                 4                 92              90-119            [3]             []


Warning: threads corresponding to process 11588 are mapped to multiple L3cache(s) ([0, 1, 2, 3])
[azureuser@cghb120v3 ~]$
```

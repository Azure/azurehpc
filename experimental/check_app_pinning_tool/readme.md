# HPC Application process/thread mapping/pinning checking tool

Correct mapping/pinning of HPC Application processes/threads is critical for optimal performance.
The HPC Application process/thread mapping/pinning checking tool has two main features, it allows you to quickly verify that the processes/threads associated with your HPC Application are mapped/pinned correctly/optimally or it can generate the MPI process/thread pinning syntax for OpenMPI/HPCX, Intel MPI and MVapich2 (Currently for HPC VM's based on AMD processors (HB (v1,v2 & v3) and NDv4). This tool shows you the virtual machine NUMA topology (i.e location of code id's, GPU's and NUMA domains), where the processes/threads associated with your HPC Application are mapped/pinned and warnings if they are not mapped/pinned optimally.

## Prerequisites

- python3 is installed
- hwloc package is installed

## Usage
```
 ./check_app_pinning.py -h
usage: check_app_pinning.py [-h] [-anp APPLICATION_PATTERN] [-pps] [-f]
                            [-nv TOTAL_NUMBER_VMS]
                            [-nppv NUMBER_PROCESSES_PER_VM]
                            [-ntpp NUMBER_THREADS_PER_PROCESS]
                            [-mt {openmpi,intel,mvapich2}]

optional arguments:
  -h, --help            show this help message and exit
  -anp APPLICATION_PATTERN, --application_name_pattern APPLICATION_PATTERN
                        Select the application pattern to check [string]
                        (default: None)
  -pps, --print_pinning_syntax
                        Print MPI pinning syntax (default: False)
  -f, --force           Force printing MPI pinning syntax (i.e ignore
                        warnings) (default: False)
  -nv TOTAL_NUMBER_VMS, --total_number_vms TOTAL_NUMBER_VMS
                        Total number of VM's (used with -pps) (default: 1)
  -nppv NUMBER_PROCESSES_PER_VM, --number_processes_per_vm NUMBER_PROCESSES_PER_VM
                        Total number of MPI processes per VM (used with -pps)
                        (default: None)
  -ntpp NUMBER_THREADS_PER_PROCESS, --number_threads_per_process NUMBER_THREADS_PER_PROCESS
                        Number of threads per process (used with -pps)
                        (default: None)
  -mt {openmpi,intel,mvapich2}, --mpi_type {openmpi,intel,mvapich2}
                        Select which type of MPI to generate pinning syntax
                        (used with -pps) (default: openmpi)
```
## Examples
You are on a Standard_HB120-64rs_v3 virtual machine, you would like to know the correct HPCX pinning syntax to pin 16 MPI
processes and 4 threads per process.

```
check_app_pinning.py -pps -nppv 16 -ntpp 4

Virtual Machine (Standard_HB120-64rs_v3, cghb64v3) Numa topology

NumaNode id  Core ids   (Mask)                             GPU ids   
============ ============================================ ==========
0            ['0-15']  (0xffff)                           []        
1            ['16-31'] (0xffff0000)                       []        
2            ['32-47'] (0xffff00000000)                   []        
3            ['48-63'] (0xffff000000000000)               [] 

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


Process/thread openmpi MPI Mapping/pinning syntax for total 16 processes ( 16 processes per VM and 4 threads per process)

-np 16 --bind-to l3cache --map-by ppr:4:numa
```

Note: Incorrect number of processes and threads is flagged with warnings


You have a hybrid parallel application (called hpcapp) running on multiple virtual machines (HB120_v2). You would like to check if the processes and threads are pinned correctly. On one of the virtual machine you run
```
check_app_pinning.py -anp hpcapp

Virtual Machine (Standard_HB120_v2, cghb120v2) Numa topology

NumaNode id  Core ids   (Mask)                             GPU ids   
============ ============================================ ==========
0            ['0-29']  (0x3fffffff)                       []        
1            ['30-59'] (0xfffffffc0000000)                []        
2            ['60-89'] (0x3fffffff000000000000000)        []        
3            ['90-119'](0xfffffffc0000000000000000000000) [] 

L3Cache id   Core ids
============ ====================
0            ['0-2']
1            ['3-5']
2            ['6-9']
3            ['10-13']
4            ['14-17']
5            ['18-21']
6            ['22-25']
7            ['26-29']
8            ['30-32']
9            ['33-35']
10           ['36-39']
11           ['40-43']
12           ['44-47']
13           ['48-51']
14           ['52-55']
15           ['56-59']
16           ['60-62']
17           ['63-65']
18           ['66-69']
19           ['70-73']
20           ['74-77']
21           ['78-81']
22           ['82-85']
23           ['86-89']
24           ['90-92']
25           ['93-95']
26           ['96-99']
27           ['100-103']
28           ['104-107']
29           ['108-111']
30           ['112-115']
31           ['116-119']

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
./check_app_pinning.py -anp hello

Virtual Machine (cgndv4) Numa topology

NumaNode id  Core ids    (Mask)                       GPU ids
============ ======================================= ==========
0            ['0-23']   (0xffffff)                   [3, 2]
1            ['24-47']  (0xffffff000000)             [1, 0]
2            ['48-71']  (0xffffff000000000000)       [7, 6]
3            ['72-95']  (0xffffff000000000000000000) [5, 4]


Application (hello) Mapping/pinning

PID          Threads           Running Threads   Last core id    Core id mapping   Numa Node ids   GPU ids
============ ================= ================= ==============  ================= =============== ===============
32473        6                 0                 0                  0                 [0]             3
32474        6                 2                 24                 24                [1]             1
32475        6                 2                 48                 48                [2]             7
32476        6                 2                 72                 72                [3]             5


Warning: 2 threads are mapped to 1 core(s), for pid (32474)
Warning: 2 threads are mapped to 1 core(s), for pid (32475)
Warning: 2 threads are mapped to 1 core(s), for pid (32476)
Warning: Virtual Machine has 8 GPU's, but only 6 threads are running


For HB_v3 will also show the L3cache topology.

[azureuser@cghb120v3 ~]$ ./check_app_pinning_new.py -anp hello

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

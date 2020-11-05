# Notes on health-check scripts

Detailed documentation on how to run these health checks on HBV2, HB and HC can be found [here](https://techcommunity.microsoft.com/t5/AzureCAT/Health-checks-for-HPC-workloads-on-Microsoft-Azure/ba-p/837843)

## Some alternative ways to run health-checks

### Alternative Stream test
To run stream tests on HB/HC:
```
azhpc-scp -r $azhpc_dir/apps hpcadmin@headnode:
azhpc-run -n headnode apps/health_checks/install_stream_test.sh
azhpc-run -n compute /data/node_utils/Stream/stream_test.sh
```

### Alternative Intel Memory Latency Checker (MLC) Memory bandwidth test
Intel MLC is a free intel tool that can be used to measure a VM memory bandwidth, it runs other VM latency tests/checks,
to see all options passed the --h arg.

To install Intel MLC
```
./install_mlc.sh blob_sas_url_full_path_to_mlc_tar.gz
```

To run all intel MLC memory bandwidth tests
```
run_all_mlc_stream.sh /path/to/hostfile
```
>Note: You can run Intel MLC on AMD processors also. MLC required hugepages to be enabled. If you do not require
hugepages you may need to disable them after running the MLC tests.

### Mellanox clusterkit tests
Mellanox OFED contains clusterkit (Node and IB healthcheck), its included on CentOS-HPC marketplace images.

You can access it by loading the mpi/hpcx mpi environment.

```
module load mpi/hpcx

which clusterkit.sh
/opt/hpcx-v2.7.0-gcc-MLNX_OFED_LINUX-5.1-0.6.6.0-redhat7.7-x86_64/clusterkit/bin/clusterkit.sh
```

To run the clusterkit healthcheck tests.
>Note: Execute clusterkit scripts on a compute node (HBv2, HB or HC)
```
run_clusterkit.sh /path/to/hostlist
```
>Note: The hostlist needs to contain an even number of hosts.
The results for the tests will be location in a directory with the following format "date_time", in the current working directory.

To check the clusterkit results and generate a report.

```
check_clusterkit_results.sh /path/to/results/dir
```
The following report will be generated.

```
Examined nodes: hbv2vmss00000a,hbv2vmss00000b,hbv2vmss00000c,hbv2vmss00000d,hbv2vmss00000e,hbv2vmss00000f,hbv2vmss00000h,hbv2vmss00000j,hbv2vmss00000m,hbv2vmss00000n,hbv2vmss00000o,hbv2vmss00000p,hbv2vmss00000r,hbv2vmss00000s,hbv2vmss00000t,hbv2vmss00000u,hbv2vmss00000v,hbv2vmss00000w,hbv2vmss00000x,hbv2vmss00000y,hbv2vmss00000z,hbv2vmss[000000-000002,000004-000009]

===============================
Bandwidth

Minimum bandwidth: 40029 MB/sec hbv2vmss000006, hbv2vmss00000j  (5.0% below the avg)
Maximum bandwidth: 42938 MB/sec hbv2vmss00000e, hbv2vmss00000p
Average bandwidth: 42107 MB/sec

Nodes exhibited poor perforamce with all other nodes:
minimal bandwidth of 40247 MB/s
hbv2vmss000006,hbv2vmss00000b

===============================
Noise

Minimum efficiency: 0.816       hbv2vmss00000d
Maximum efficiency: 0.828       hbv2vmss00000y
Average efficiency: 0.823

===============================
Latency

Minimum latency: 1.429 usec     hbv2vmss00000z, hbv2vmss00000v
Maximum latency: 1.915 usec     hbv2vmss000002, hbv2vmss00000a
Average latency: 1.743 usec
```
>Note: You can run the clustrekit.sh or clusterkit scripts directly to give you more control, pass "-h" to see all options. You can also customize your heathcheck report by using the analysis.py script (-h to see all options).

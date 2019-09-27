# IOR and mdtest

IOR can be built on any kind of VM SKU as long as it uses the CentOS-HPC 7.6 image. See one of the examples for building a Cluster with HB or HC skus and PBS. (e.g. [simple_hpc_pbs](../../examples/simple_hpc_pbs/readme.md))

## Log-on to the headnode

```
azhpc-connect headnode
cd /apps
git clone https://github.com/Azure/azurehpc.git
```

## Build IOR
Build IOR/mdtest from the build script.  This will by default install ior and mdtest into /apps/ior and create a modulefile. You can override the installation path by providing it as a parameter on the `build_ior.sh` script

For PBS :
```
qsub /apps/azurehpc/ior/build_ior.sh
```

For LSF :
```
bsub -q <queue> -o %J.log -e %J.err "bash /apps/azurehpc/ior/build_ior.sh"
```

## Run IOR and MDTEST

Now submit and run (e.g on HB):

```
qsub -l select=2:ncpus=60:mpiprocs=15 /apps/azurehpc/ior/ior.sh
```

> Note: this will run on 2 node and 15 processes per node.

The `ior.sh` script runs a throughput (N-N and N-1) and IOPS test.

A metadata I/O benchmark test can be run using the `mdtest.sh` script.

```
qsub -l select=2:ncpus=60:mpiprocs=15 /apps/azurehpc/ior/mdtest.sh
```

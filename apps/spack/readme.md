# Spack

## Prerequisites
Python3 needs to be installed on all computational resources using spack.

[Spack](https://spack.readthedocs.io/en/latest/) is a package management tool designed to support multiple versions and configurations of software on a wide variety of platforms and environments. It was designed for large supercomputing center, where many users and application teams share common installations of software on clusters.

Spack will build and install software for HB, HBv2 or HC sku's with CentOS-HPC 7.7 (using the provided MPI libraries). See one of the examples for building a Cluster with HB or HC skus and PBS. (e.g. [simple_hpc_pbs](../../examples/simple_hpc_pbs/readme.md))


Copy apps dir to the headnode (to access spack build script from the headnode)
```
azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.
```


log-on to the headnode
```
azhpc-connect -u hpcuser headnode
```


Build/install spack using the build script.  This will install spack into /apps/spack and set-up some suitable defaults:
```
    build_spack.sh <SKU_TYPE> <EMAIL_ADDRESS> <STORAGE_ENDPOINT>
```
Where <SKU_TYPE> is hb, hbv2 or hc (used as sku identifier to indicate which SKU the software was built on), <EMAIL_ADDRESS> will be associated with the GPG key that is generated (used when accessing/downloading pre-built binaries from a build cache) and <STORAGE_ENDPOINT> is the storage account used to store the buildcache.
>note If the SKU_TYPE command line argument is the only arg given then spack will be installed and set-up without buildcache support.

Example, building and installing osu-micro-benchmarks using different MPI libraries (from CentOS-HPC 7.7 image)

Using mvapich2
```
spack install osu-micro-benchmarks%gcc@9.2.0^mvapich2@2.3.3
```
Using openmpi
```
spack install osu-micro-benchmarks%gcc@9.2.0^openmpi@4.0.3
```
Using hpcx
```
spack install osu-micro-benchmarks%gcc@9.2.0^hpcx@2.6.0
```
Using intel mpi 
```
source /opt/intel/compilers_and_libraries_2020.1.217/linux/mpi/intel64/bin/mpivars.sh
spack install --dirty osu-micro-benchmarks%gcc@9.2.0^intel-mpi@2020.1.217
```

Some example PBS scripts have been provided to show how run the osu-micro-benchmarks.
To run the osu bandwidth and latency tests using the openmpi version.
```
qsub -l select=2:ncpus=120:mpiprocs=1 osu_bw_openmpi.pbs
```

To add the built/installed osu-micro-benchmarks to a buildcache (i.e repository) on Azure blob storage
for later retrival and installation.

First, install the software (See above)

Check that your azure storage blob mirror is set up.
```
[hpcuser@headnode ~]$ spack mirror list
spack-public       https://spack-llnl-mirror.s3-us-west-2.amazonaws.com/
hbv2_buildcache    azure://cgspackstore.blob.core.windows.net/buidcache/hbv2
```

Create a buildcache in your azure storage blob mirror
```
spack buildcache create --rebuild-index -k ${sku_type}_gpg -m ${sku_type}_buildcache osu-micro-benchmarks%gcc@9.2.0^mvapich2@2.3.3
```

To install software from your azure storage blob buildcache.
```
spack buildcache install osu-micro-benchmarks^mvapich2
```

To see all available gpg keys
```
spack gpg list
```

To set-up your blob storage as a buildcache location, you need to add a mirror.
```
spack mirror add ${sku_type}_buildcache azure://<STORAGE_ACCOUNT_NAME>.blob.core.windows.net/buildcache/${sku_type} 
```

To see what software is available for installation from the binary buildcache (blob storage).
```
   spack buildcache list
```

To install software available from the buildcache (blob storage).

```
   spack buildcache install <spec> or <hash>
```

# Spack

[Spack](https://spack.readthedocs.io/en/latest/) is a package management tool designed to support multiple versions and configurations of software on a wide variety of platforms and environments. It was designed for large supercomputing center, where many users and application teams share common installations of software on clusters.

Spack will build and install software for HB or HC sku's with CentOS-HPC 7.6 (using the provided MPI libraries). See one of the examples for building a Cluster with HB or HC skus and PBS. (e.g. [simple_hpc_pbs](../../examples/simple_hpc_pbs/readme.md))


Copy apps dir to the headnode (to access spack build script from the headnode)
```
azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.
```


log-on to the headnode
```
azhpc-connect headnode
```


Build/install spack using the build script.  This will install spack into /apps/spack and set-up some suitable defaults:
```
    build_spack.sh <SKU_NAME> <EMAIL_ADDRESS>
```
Where <SKU_NAME> is hb or hc (used as sku identifier to indicate which SKU the software was built on) and <EMAIL_ADDRESS> will be associated with the GPG key that is generated (used when accessing/downloading pre-built binaries from a build cache).

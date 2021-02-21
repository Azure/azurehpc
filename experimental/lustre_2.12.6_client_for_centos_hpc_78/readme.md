## Build lustre 2.12.6 client for CentOS-HPC 7.8 image (withy MOFED 5.2.x)

You will get the following error it you attempt to build the official latest lustre 2.12.6 client on the new CentOS-HPC 7.8 image
```
Building for 3.10.0-1127.19.1.el7.x86_64
Building initial module for 3.10.0-1127.19.1.el7.x86_64
configure: error: no OFED nor kernel OpenIB gen2 headers present
Error! Bad return status for module build on kernel: 3.10.0-1127.19.1.el7.x86_64 (x86_64)
Consult /var/lib/dkms/lustre-client/2.12.6/build/make.log for more information.
warning: %post(lustre-client-dkms-2.12.6-1.el7.noarch) scriptlet failed, exit status 10

  Installing : lustre-client-dkms-2.12.6-1.el7.noarch                      7/12
Loading new lustre-client-2.12.6 DKMS files...
Building for 3.10.0-1127.19.1.el7.x86_64
Building initial module for 3.10.0-1127.19.1.el7.x86_64
configure: error: no OFED nor kernel OpenIB gen2 headers present
Error! Bad return status for module build on kernel: 3.10.0-1127.19.1.el7.x86_64 (x86_64)
Consult /var/lib/dkms/lustre-client/2.12.6/build/make.log for more information.
warning: %post(lustre-client-dkms-2.12.6-1.el7.noarch) scriptlet failed, exit status 10
```
These error are due to upgrading the MOFED grom 5.1.x to 5.2.1.0.4.1

The script called build_lustre_2.12.6_client_centOS_hpc_78.sh can be used to build a lustre 2.12.6 client on the new CentOS-HPC image (with MOFED 5.2.x). This script can easily be include in a custom image.

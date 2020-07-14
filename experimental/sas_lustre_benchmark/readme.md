
This is a test specifically set up to run the SAS benchmark on a Lustre filesystem using standard disks on Azure.

```
./param_sweep \
    <resource-group-prefix> \
    <oss-instances> \
    <oss_sku> \
    <client-instances> \
    <client-sku>
```

Example:

```
# 2 cores per VM runs
./param_sweep.sh \
    $USER
    24
    Standard_E16s_v3
    "8 16 24"
    "Standard_E8-4s_v3 Standard_E16-4s_v3"

# 4 cores per VM runs
./param_sweep.sh \
    $USER
    24
    Standard_E16s_v3
    "4 8 12"
    "Standard_E8s_v3 Standard_E16-8s_v3"
```
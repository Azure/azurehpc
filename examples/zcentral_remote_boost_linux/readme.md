# Build a Linux visualization VM and install HPE ZCentral Remote Boost (formerly HP RGS)

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/zcentral_remote_boost_linux/config.json)

This example will create and a Linux (CentOS 7.8) visualization vm with HPE ZCentral Remote Boost.

>NOTE: 
- MAKE SURE you have followed the steps in [prerequisite](../../tutorials/prerequisites.md) before proceeding here
- MAKE SURE you have the ZCentral Remote Boost installer and license file uploaded in the Azure Storage blob (Use the azurehpc sas_url macros).

First initialise a new project. AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
azhpc-init -c $azhpc_dir/examples/zcentral_remote_boost_linux -d zcentral_remote_boost_linux -s
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

```
azhpc-init -c $azhpc_dir/examples/zcentral_remote_boost_linux -d zcentral_remote_boost_linux -v resource_group=azhpc-cluster,location=southcentralus
```

Create/build the Linux visualization vm

```
cd zcentral_remote_boost_linux
azhpc-build
```

Allow ~10 minutes for deployment.

# Remote Visualization on Linux VM

Download and install ZCentral REmote Boost receiver on local WS. Connect to ZCEntral Remote boost sender using its public IP address.

![Alt text1](/examples/zcentral_remote_boost_linux/images/zcentral_receiver.JPG?raw=true "zcentral receiver")

Once you connect to the Zcentral Remote Boost Linux Sender, give your username and password.

![Alt text2](/examples/zcentral_remote_boost_linux/images/zcentral_login.JPG?raw=true "zcentral login")

You should then see your Linux REmote visualization desktop.

![Alt text3](/examples/zcentral_remote_boost_linux/images/zcentral_linux_desktop.JPG?raw=true "zcentral desktop")


# Creating and using a custom image
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/image?branchName=master)

This example shows how to create a custom image and later how to use it to deploy VMs or VMSS.

## Creating the image

The `create_image.json` contains all the resources and settings for creating a managed image.

```
$ azhpc-init -d <workdir> -v uuid=12345,location=somewhere,image_name=foo
$ cd <workdir>
$ azhpc-build -c create_image.json
```

This will build a simple VM and capture it as a managed image, as you can see in the conguration file there is a `builder` VM being deployed as well, acting as a jumpbox for the AzureHPC scripts to be sucessfully run, especially the `deprovision.sh` one. To apply this on your own VMs, just add the `deprovision` and the `create_image` tags and script to your configuration file.

```json
    {
        "script": "deprovision.sh",
        "tag": "deprovision",
        "sudo": true
    },
    {
        "type": "local_script",
        "script": "create_image.sh",
        "args": [
            "variables.resource_group",
            "master",
            "variables.image_name",
            "variables.image_resource_group"
        ]
    }
```

The managed image can be stored in a different resource group (located in the same region and subscription) than the VM being deployed in, so you can use a global resource group for all your images. Be aware that if an image already exists it will be overriden without prompting you to confirm its replacement.

If you need to reboot the VM between installation scripts, just add additional waits in your install section like the extract from the `NVIDIA` example below. The jumpbox need to have the tag *sleep*. This is useful especially when rebooting imply finalization of installation and takes more than the 30s timeout in azhpc.

```json
    {
        "script": "update_kernel.sh",
        "tag": "nvidia",
        "reboot": true,
        "sudo": true
    },
    {
        "script": "wait.sh",
        "args": ["30"],
        "tag": "sleep"
    },
    {
        "script": "install_lis.sh",
        "tag": "nvidia",
        "reboot": true,
        "sudo": true
    },
    {
        "script": "wait.sh",
        "args": ["30"],
        "tag": "sleep"
    },
    {
        "script": "cuda_drivers.sh",
        "tag": "nvidia",
        "sudo": true
    },
```

## Using the image

Once you have built an image juste use the macro `image.[resource_group].[image_name]` for the image value of the resources to deploy as shown in the snippet below. The resources need to be deployed in the same region than when the image is stored.

```json
    "variables": {
        "image_name": "<NOT-SET>",
        "image_resource_group": "<NOT-SET>"
    },
    "resources": {
        "headnode": {
            "type": "vm",
            "vm_type": "variables.vm_type",
            "public_ip": true,
            "image": "image.{{variables.image_resource_group}}.{{variables.image_name}}",
            "subnet": "compute",
            "tags": [
            ]
        }
    }
```

To build with the captured image run 
```
$ azhpc-build -c use_image.json
```

## Cleanup all
```
$ azhpc-destroy -c use_image.json --no-wait
$ azhpc-destroy -c create_image.json --no-wait
```

Manually remove the image resource group if you are using one (by default this is the case)

{
    "location": "variables.location",
    "resource_group": "variables.resource_group",
    "proximity_placement_group_name": "variables.ppg_name",
    "install_from": "headnode",
    "admin_user": "hpcadmin",
    "variables": {
        "image": "OpenLogic:CentOS:7.7:latest",
        "location": "westeurope",
        "storage_sku": "__storage_sku__",
        "storage_instances": __storage_instances__,
        "client_sku": "Standard_D32s_v3",
        "client_accelerated_networking": __client_accelerated_networking__,
        "client_instances": __client_instances__,
        "resource_group": "paul-test-beegfs",
        "availability_set": "{{variables.resource_group}}-avset",
        "vnet_resource_group": "variables.resource_group",
        "beegfs_disk_type": "data_disk",
        "beegfs_node_type": "all",
        "beegfs_pools": "false",
        "beegfs_pools_restart": "false",
        "ppg_name": "{{variables.resource_group}}-ppg"
    },
    "vnet": {
        "resource_group": "variables.vnet_resource_group",
        "name": "hpcvnet",
        "address_prefix": "10.2.0.0/20",
        "subnets": {
            "admin": "10.2.1.0/24",
            "viz": "10.2.2.0/24",
            "compute": "10.2.4.0/22"
        }
    },
    "resources": {
        "headnode": {
            "type": "vm",
            "vm_type": "Standard_D8s_v3",
            "accelerated_networking": true,
            "proximity_placement_group": true,
            "public_ip": true,
            "image": "variables.image",
            "subnet": "compute",
            "tags": [
                "cndefault",
                "disable-selinux",
                "beegfspkgs",
                "beegfsc"
            ]
        },
        "beegfsm": {
            "type": "vm",
            "vm_type": "Standard_F8s_v2",
            "accelerated_networking": true,
            "proximity_placement_group": true,
            "availability_set": "variables.availability_set",
            "image": "variables.image",
            "subnet": "compute",
            "tags": [
                "beegfspkgs",
                "beegfsm",
                "disable-selinux",
                "beegfsc"
            ]
        },
        "beegfssm": {
            "type": "vmss",
            "vm_type": "variables.storage_sku",
            "instances": "variables.storage_instances",
            "accelerated_networking": true,
            "proximity_placement_group": true,
            "availability_set": "variables.availability_set",
            "image": "variables.image",
            "subnet": "compute",
            "storage_sku": "Premium_LRS",
            "resource_tags": {
                "$perfOptimizationLevel": 1
            },
            "data_disks": [1024, 1024, 1024, 1024, 1024, 1024],
            "tags": [
                "beegfspkgs",
                "beegfssd",
                "beegfsmd",
                "beegfsc",
                "sambaserver",
                "cndefault",
                "disable-selinux"
            ]
        },
        "win": {
            "type": "vm",
            "os_storage_sku": "Standard_LRS",
            "vm_type": "variables.client_sku",
            "password": "Microsoft123!",
            "instances": "variables.client_instances",
            "accelerated_networking": "variables.client_accelerated_networking",
            "proximity_placement_group": true,
            "image": "MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest",
            "subnet": "compute",
            "tags": [
                "client"
            ]
        }
    },
    "install": [
        {
            "script": "enable_ssh.sh",
            "type": "local_script",
            "args": [
                "variables.resource_group",
                "win",
                "variables.client_instances",
                "$(<hpcadmin_id_rsa.pub)"
            ],
            "deps": [
                "install_sshd.ps1"
            ]
        },
        {
            "script": "disable-selinux.sh",
            "tag": "disable-selinux",
            "sudo": true
        },
        {
            "script": "beegfspkgs.sh",
            "tag": "beegfspkgs",
            "sudo": true
        },
        {
            "script": "beegfsm.sh",
            "args": [
                "/data/beegfs/mgmt"
            ],
            "tag": "beegfsm",
            "sudo": true
        },
        {
            "script": "beegfssd.sh",
            "args": [
                "variables.beegfs_disk_type",
                "variables.beegfs_node_type",
                "variables.beegfs_pools",
                "variables.beegfs_pools_restart",
                "$(<hostlists/tags/beegfsm)"
            ],
            "tag": "beegfssd",
            "sudo": true
        },
        {
            "script": "beegfsmd.sh",
            "args": [
                "variables.beegfs_disk_type",
                "variables.beegfs_node_type",
                "variables.beegfs_pools",
                "$(<hostlists/tags/beegfsm)"
            ],
            "tag": "beegfsmd",
            "sudo": true
        },

        {
            "script": "beegfsc.sh",
            "args": [
                "$(<hostlists/tags/beegfsm)"
            ],
            "tag": "beegfsc",
            "sudo": true
        },
        {
            "script": "beegfssmb.sh",
            "tag": "sambaserver",
            "sudo": true
        },
        {
            "script": "cndefault.sh",
            "tag": "cndefault",
            "sudo": true
        },
        {
            "script": "install_fio.sh",
            "type": "local_script",
            "args": [
                "variables.resource_group",
                "win",
                "variables.client_instances",
                "$(<hpcadmin_id_rsa.pub)"
            ],
            "deps": [
                "install_fio.ps1"
            ]
        },
        {
            "script": "round_robin_mount_beegfs.sh",
            "type": "local_script",
            "args": [
                "variables.resource_group",
                "beegfssm",
                "win",
                "variables.client_instances"
            ],
            "deps": [
                "config.json"
            ]
        },
        {
            "script": "run_benchmark.sh",
            "type": "local_script",
            "args": [ "win", "1", "1", "8" ]
        },
        {
            "script": "run_benchmark.sh",
            "type": "local_script",
            "args": [ "win", "2", "1", "8" ]
        },
        {
            "script": "run_benchmark.sh",
            "type": "local_script",
            "args": [ "win", "4", "1", "8" ]
        },
        {
            "script": "run_benchmark.sh",
            "type": "local_script",
            "args": [ "win", "6", "1", "8" ]
        },
        {
            "script": "run_benchmark.sh",
            "type": "local_script",
            "args": [ "win", "8", "1", "8" ]
        },
        {
            "script": "run_benchmark.sh",
            "type": "local_script",
            "args": [ "win", "10", "1", "8" ]
        },
        {
            "script": "run_benchmark.sh",
            "type": "local_script",
            "args": [ "win", "12", "1", "8" ]
        },
        {
            "script": "run_benchmark.sh",
            "type": "local_script",
            "args": [ "win", "14", "1", "8" ]
        },
        {
            "script": "run_benchmark.sh",
            "type": "local_script",
            "args": [ "win", "16", "1", "8" ]
        }
    ]
}

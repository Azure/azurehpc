import json
import uuid

class ArmTemplate:
    def __init__(self):
        self.parameters = {}
        self.variables = {}
        self.resources = []
        self.outputs = {}
    
    def _read_network(self, cfg):
        location = cfg["location"]
        vnet_name = cfg["vnet"]["name"]
        address_prefix = cfg["vnet"]["address_prefix"]      
        subnet_names = cfg["vnet"]["subnets"]
        subnets = []
        for subnet_name in subnet_names:
            subnet_address_prefix = cfg["vnet"]["subnets"][subnet_name]
            subnets.append({
                "name": subnet_name,
                "properties": {
                    "addressPrefix": subnet_address_prefix
                }
            })

        res = {
            "apiVersion": "2018-10-01",
            "type": "Microsoft.Network/virtualNetworks",
            "name": vnet_name,
            "location": location,
            "properties": {
                "addressSpace": {
                    "addressPrefixes": [
                        address_prefix
                    ]
                },
                "subnets": subnets
            },
            "resources": []
        }

        self.resources.append(res)

    def _read_vm(self, cfg, r):
        res = cfg["resources"][r]
        rsize = res["vm_type"]
        rimage = res["image"]
        rpip = res.get("public_ip", False)
        rppg = res.get("proximity_placement_group", False)
        rsubnet = res["subnet"]
        ran = res.get("accelerated_networking", False)
        rstoragesku = res.get("storage_sku", "StandardSSD_LRS")
        rlowpri = res.get("low_priority", False)
        rosdisksize = res.get("os_disk_size", 32)
        rosstoragesku = res.get("os_storage_sku", "StandardSSD_LRS")
        rdiskcount = len(res.get("data_disks", []))
        loc = cfg["location"]
        adminuser = cfg["admin_user"]
        rrg = cfg["resource_group"]
        vnetname = cfg["vnet"]["name"]
        vnetrg = cfg["vnet"].get("resource_group", rrg)
        if vnetrg == rrg:
            rsubnetid = "[resourceId('Microsoft.Network/virtualNetworks/subnets', '{}', '{}')]".format(vnetname, rsubnet)
        else:
            rsubnetid = "[resourceId('{}', 'Microsoft.Network/virtualNetworks/subnets', '{}', '{}')]".format(vnetrg, vnetname, rsubnet)
        rpassword = res.get("password", "<no-password>")
        with open(adminuser+"_id_rsa.pub") as f:
            sshkey = f.read().strip()
        
        nicdeps = []

        if vnetrg == rrg:
            nicdeps.append("Microsoft.Network/virtualNetworks/"+vnetname)

        if rpip:
            pipname = r+"PIP"
            dnsname = r+str(uuid.uuid4())[:6]
            nsgname = r+"NSG"

            nicdeps.append("Microsoft.Network/publicIpAddresses/"+pipname)
            nicdeps.append("Microsoft.Network/networkSecurityGroups/"+nsgname)

            self.resources.append({
                "type": "Microsoft.Network/publicIPAddresses",
                "apiVersion": "2018-01-01",
                "name": pipname,
                "location": loc,
                "dependsOn": [],
                "tags": {},
                "properties": {
                    "dnsSettings": {
                        "domainNameLabel": dnsname
                    }
                }
            })

            self.resources.append({
                "type": "Microsoft.Network/networkSecurityGroups",
                "apiVersion": "2015-06-15",
                "name": nsgname,
                "location": loc,
                "dependsOn": [],
                "tags": {},
                "properties": {
                    "securityRules": [
                        {
                            "name": "default-allow-ssh",
                            "properties": {
                                "protocol": "Tcp",
                                "sourcePortRange": "*",
                                "destinationPortRange": "22",
                                "sourceAddressPrefix": "*",
                                "destinationAddressPrefix": "*",
                                "access": "Allow",
                                "priority": 1000,
                                "direction": "Inbound"
                            }
                        }
                    ]
                }
            })

        nicname = r+"NIC"
        ipconfigname = r+"IPCONFIG"
        nicprops = {
            "ipConfigurations": [
                {
                    "name": ipconfigname,
                    "properties": {
                        "privateIPAllocationMethod": "Dynamic",
                        "subnet": {
                            "id": rsubnetid
                        }
                    }
                }
            ],
            "enableAcceleratedNetworking": ran
        }

        if rpip:
            nicprops["ipConfigurations"][0]["properties"]["publicIPAddress"] = {
                "id": "[resourceId('Microsoft.Network/publicIPAddresses', '{}')]".format(pipname)
            }
            nicprops["networkSecurityGroup"] = {
                "id": "[resourceId('Microsoft.Network/networkSecurityGroups', '{}')]".format(nsgname)
            }

        self.resources.append({
            "type": "Microsoft.Network/networkInterfaces",
            "apiVersion": "2016-09-01",
            "name": nicname,
            "location": loc,
            "dependsOn": nicdeps,
            "tags": {},
            "properties": nicprops
        })

        osprofile = {
            "computerName": r,
            "adminUsername": adminuser
        }
        if rpassword != "<no-password>":
            osprofile["adminPassword"] = rpassword
        else:
            osprofile["linuxConfiguration"] = {
                "disablePasswordAuthentication": True,
                "ssh": {
                    "publicKeys": [
                        {
                            "keyData": sshkey,
                            "path": "/home/{}/.ssh/authorized_keys".format(adminuser)
                        }
                    ]
                }
            }

        self.resources.append({
            "type": "Microsoft.Compute/virtualMachines",
            "apiVersion": "2019-07-01",
            "name": r,
            "location": loc,
            "dependsOn": [
                "Microsoft.Network/networkInterfaces/"+nicname
            ],
            "tags": {},
            "properties": {
                "hardwareProfile": {
                    "vmSize": rsize
                },
                "networkProfile": {
                    "networkInterfaces": [
                        {
                            "id": "[resourceId('Microsoft.Network/networkInterfaces', '{}')]".format(nicname)
                        }
                    ]
                },
                "storageProfile": {
                    "osDisk": {
                        "createOption": "fromImage",
                        "caching": "ReadWrite",
                        "managedDisk": {
                            "storageAccountType": rosstoragesku
                        },
                        "diskSizeGb": rosdisksize
                    },
                    "imageReference": {
                        "publisher": rimage.split(":")[0],
                        "offer": rimage.split(":")[1],
                        "sku": rimage.split(":")[2],
                        "version": rimage.split(":")[3]
                    }
                },
                "osProfile": osprofile
            }
        })

    def read(self, cfg):
        self._read_network(cfg)

        resources = cfg["resources"]
        for r in resources.keys():
            rtype = cfg["resources"][r]["type"]
            if rtype == "vm":
                self._read_vm(cfg, r)

    def to_json(self):
        return json.dumps({
            "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "parameters": self.parameters,
            "variables": self.variables,
            "resources": self.resources,
            "outputs": self.outputs
        }, indent=4)
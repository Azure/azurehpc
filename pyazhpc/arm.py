import json
import uuid

class ArmTemplate:
    def __init__(self):
        self.parameters = {}
        self.variables = {}
        self.resources = []
        self.outputs = {}
    
    def _add_network(self, cfg):
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

    def _add_proximity_group(self, cfg):
        ppg = cfg.get("proximity_placement_group_name", None)
        if ppg:
            loc = cfg["location"]
            self.resources.append({
                "apiVersion": "2018-04-01",
                "type": "Microsoft.Compute/proximityPlacementGroups",
                "name": ppg,
                "location": loc
            })

    def __helper_arm_create_osprofile(self, rname, rtype, adminuser, adminpass, sshkey):
        if rtype == "vm":
            name = "computerName"
        else:
            name = "computerNamePrefix"
        
        osprofile = {
            name: rname,
            "adminUsername": adminuser
        }
        if adminpass != "<no-password>":
            osprofile["adminPassword"] = adminpass
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

        return osprofile

    def __helper_arm_create_datadisks(self, sizes, sku):
        datadisks = []
        for i, d in enumerate(sizes):
            if d < 4096:
                cacheoption = "ReadWrite"
            else:
                cacheoption = "None"
            datadisks.append({
                "caching": cacheoption,
                "managedDisk": {
                    "storageAccountType": sku
                },
                "createOption": "Empty",
                "lun": i,
                "diskSizeGB": d
            })
        return datadisks

    def __helper_arm_create_image_reference(self, refstr):
        return {
            "publisher": refstr.split(":")[0],
            "offer": refstr.split(":")[1],
            "sku": refstr.split(":")[2],
            "version": refstr.split(":")[3]
        }

    def _add_vm(self, cfg, r):
        res = cfg["resources"][r]
        rtype = res["type"]
        rsize = res["vm_type"]
        rimage = res["image"]
        rinstances = res.get("instances", 1)
        rpip = res.get("public_ip", False)
        rppg = res.get("proximity_placement_group", False)
        rppgname = cfg.get("proximity_placement_group_name", None)
        rsubnet = res["subnet"]
        ran = res.get("accelerated_networking", False)
        rlowpri = res.get("low_priority", False)
        rosdisksize = res.get("os_disk_size", 32)
        rosstoragesku = res.get("os_storage_sku", "StandardSSD_LRS")
        rdatadisks = res.get("data_disks", [])
        rstoragesku = res.get("storage_sku", "StandardSSD_LRS")
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
        
        rorig = r
        for instance in range(1, rinstances+1):    
            if rinstances > 1:
                r = "{}{:04}".format(rorig, instance)

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

            osprofile = self.__helper_arm_create_osprofile(r, rtype, adminuser, rpassword, sshkey)
            datadisks = self.__helper_arm_create_datadisks(rdatadisks, rstoragesku)
            imageref = self.__helper_arm_create_image_reference(rimage)

            deps = [ "Microsoft.Network/networkInterfaces/"+nicname ]
            if rppg:
                deps.append("Microsoft.Compute/proximityPlacementGroups/"+rppgname)

            vmres = {
                "type": "Microsoft.Compute/virtualMachines",
                "apiVersion": "2019-07-01",
                "name": r,
                "location": loc,
                "dependsOn": deps,
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
                        "imageReference": imageref,
                        "dataDisks": datadisks
                    },
                    "osProfile": osprofile
                }
            }

            if rppg:
                vmres["properties"]["proximityPlacementGroup"] = {
                    "id": "[resourceId('Microsoft.Compute/proximityPlacementGroups','{}')]".format(rppgname)
                }
            
            self.resources.append(vmres)

    def _add_vmss(self, cfg, r):
        res = cfg["resources"][r]
        rtype = res["type"]
        rsize = res["vm_type"]
        rimage = res["image"]
        rinstances = res.get("instances")
        rpip = res.get("public_ip", False)
        rppg = res.get("proximity_placement_group", False)
        rppgname = cfg.get("proximity_placement_group_name", None)
        rsubnet = res["subnet"]
        ran = res.get("accelerated_networking", False)
        rlowpri = res.get("low_priority", False)
        rosdisksize = res.get("os_disk_size", 32)
        rosstoragesku = res.get("os_storage_sku", "StandardSSD_LRS")
        rdatadisks = res.get("data_disks", [])
        rstoragesku = res.get("storage_sku", "StandardSSD_LRS")
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

        deps = []
        if vnetrg == rrg:
            deps.append("Microsoft.Network/virtualNetworks/"+vnetname)
        if rppg:
            deps.append("Microsoft.Compute/proximityPlacementGroups/"+rppgname)

        osprofile = self.__helper_arm_create_osprofile(r, rtype, adminuser, rpassword, sshkey)
        datadisks = self.__helper_arm_create_datadisks(rdatadisks, rstoragesku)
        imageref = self.__helper_arm_create_image_reference(rimage)

        nicname = r+"NIC"
        ipconfigname = r+"IPCONFIG"
        vmssres = {
            "type": "Microsoft.Compute/virtualMachineScaleSets",
            "apiVersion": "2019-07-01",
            "name": r,
            "location": loc,
            "dependsOn": deps,
            "tags": {},
            "sku": {
                "name": rsize,
                "capacity": rinstances
            },
            "properties": {
                "overprovision": True,
                "upgradePolicy": {
                    "mode": "manual"
                },
                "virtualMachineProfile": {
                    "storageProfile": {
                        "osDisk": {
                            "createOption": "FromImage",
                            "caching": "ReadWrite",
                            "managedDisk": {
                                "storageAccountType": rosstoragesku
                            },
                            "diskSizeGb": rosdisksize,
                        },
                        "dataDisks": datadisks,
                        "imageReference": imageref
                    },
                    "osProfile": osprofile,
                    "networkProfile": {
                        "networkInterfaceConfigurations": [
                            {
                                "name": nicname,
                                "properties": {
                                    "primary": "true",
                                    "ipConfigurations": [
                                        {
                                            "name": ipconfigname,
                                            "properties": {
                                                "subnet": {
                                                    "id": rsubnetid
                                                }
                                            }
                                        }
                                    ],
                                    "enableAcceleratedNetworking": ran
                                }
                            }
                        ]
                    }
                },
                "singlePlacementGroup": True,
                "platformFaultDomainCount": 5
            }
        }
        
        if rppg:
            vmssres["properties"]["proximityPlacementGroup"] = {
                "id": "[resourceId('Microsoft.Compute/proximityPlacementGroups','{}')]".format(rppgname)
            }

        self.resources.append(vmssres)


    def read(self, cfg):
        self._add_network(cfg)
        self._add_proximity_group(cfg)

        resources = cfg["resources"]
        for r in resources.keys():
            rtype = cfg["resources"][r]["type"]
            if rtype == "vm":
                self._add_vm(cfg, r)
            elif rtype == "vmss":
                self._add_vmss(cfg, r)

    def to_json(self):
        return json.dumps({
            "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "parameters": self.parameters,
            "variables": self.variables,
            "resources": self.resources,
            "outputs": self.outputs
        }, indent=4)
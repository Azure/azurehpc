import json
import sys
import uuid

import azlog
import azutil

log = azlog.getLogger(__name__)

class ArmTemplate:
    def __init__(self):
        self.parameters = {}
        self.variables = {}
        self.resources = []
        self.outputs = {}

        self.avsets = set()

    def _add_network(self, cfg):
        resource_group = cfg["resource_group"]
        vnet_resource_group = cfg["vnet"].get("resource_group", resource_group)
        if resource_group != vnet_resource_group:
            log.debug(f"using an existing vnet in {vnet_resource_group}")
            return

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

        gtags = cfg.get("global_tags", {})

        res = {
            "apiVersion": "2018-10-01",
            "type": "Microsoft.Network/virtualNetworks",
            "name": vnet_name,
            "location": location,
            "tags": gtags,
            "properties": {
                "addressSpace": {
                    "addressPrefixes": [
                        address_prefix
                    ]
                },
                "subnets": subnets
            }
        }
        self.resources.append(res)

        resource_group = cfg["resource_group"]
        for peer_name in cfg["vnet"].get("peer", {}).keys():
            peer_resource_group = cfg["vnet"]["peer"][peer_name]["resource_group"]
            peer_vnet_name = cfg["vnet"]["peer"][peer_name]["vnet_name"]

            self.resources.append({
                "type": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings",
                "apiVersion": "2019-11-01",
                "name": f"{vnet_name}/{peer_name}-{peer_resource_group}",
                "tags": gtags,
                "properties": {
                    "remoteVirtualNetwork": {
                        "id": f"[resourceId('{peer_resource_group}', 'Microsoft.Network/virtualNetworks', '{peer_vnet_name}')]"
                    },
                    "allowVirtualNetworkAccess": True,
                    "allowForwardedTraffic": True,
                    "allowGatewayTransit": False,
                    "useRemoteGateways": False,
                },
                "dependsOn": [
                    f"Microsoft.Network/virtualNetworks/{vnet_name}"
                ]
            })

            self.resources.append({
                "type": "Microsoft.Resources/deployments",
                "apiVersion": "2017-05-10",
                "name": f"{peer_resource_group}peer",
                "tags": gtags,
                "resourceGroup": peer_resource_group,
                "properties": {
                    "mode": "Incremental",
                    "template": {
                        "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                        "contentVersion": "1.0.0.0",
                        "parameters": {},
                        "variables": {},
                        "resources": [
                            {
                                "type": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings",
                                "apiVersion": "2019-11-01",
                                "name": f"{peer_vnet_name}/{peer_name}-{resource_group}",
                                "tags": gtags,
                                "properties": {
                                    "remoteVirtualNetwork": {
                                        "id": f"[resourceId('{resource_group}', 'Microsoft.Network/virtualNetworks', '{vnet_name}')]"
                                    },
                                    "allowVirtualNetworkAccess": True,
                                    "allowForwardedTraffic": True,
                                    "allowGatewayTransit": False,
                                    "useRemoteGateways": False
                                }
                            }
                        ],
                        "outputs": {}
                    },
                    "parameters": {}
                },
                "dependsOn": [
                    f"Microsoft.Network/virtualNetworks/{vnet_name}"
                ]
            })

        # private dns
        dns_domain = cfg["vnet"].get("dns_domain", None)
        if dns_domain:
            log.info(f"add private dns ({dns_domain})")
            self.resources.append({
                "type": "Microsoft.Network/privateDnsZones",
                "apiVersion": "2018-09-01",
                "name": dns_domain,
                "tags": gtags,
                "location": "global",
                "properties": {},
                "resources": [{
                    "type": "Microsoft.Network/privateDnsZones/virtualNetworkLinks",
                    "apiVersion": "2018-09-01",
                    "name": f"[concat('{dns_domain}', '/{vnet_name}')]",
                    "location": "global",
                    "dependsOn": [
                        f"[resourceId('Microsoft.Network/privateDnsZones', '{dns_domain}')]"
                    ],
                    "properties": {
                        "registrationEnabled": True,
                        "virtualNetwork": {
                            "id": f"[resourceId('Microsoft.Network/virtualNetworks', '{vnet_name}')]"
                        }
                    }
                }]
            })

        # add route tables first (and keep track of mapping to subnet)
        route_table_map = {}
        for route_name in cfg["vnet"].get("routes", {}).keys():
            route_address_prefix = cfg["vnet"]["routes"][route_name]["address_prefix"]
            route_next_hop = cfg["vnet"]["routes"][route_name]["next_hop"]
            route_subnet = cfg["vnet"]["routes"][route_name]["subnet"]

            route_table_map[route_subnet] = route_name

            self.resources.append({
                "type": "Microsoft.Network/routeTables",
                "apiVersion": "2019-11-01",
                "name": route_name,
                "tags": gtags,
                "location": location,
                "properties": {
                    "disableBgpRoutePropagation": False,
                    "routes": [
                        {
                            "name": route_name,
                            "properties": {
                                "addressPrefix": route_address_prefix,
                                "nextHopType": "VirtualAppliance",
                                "nextHopIpAddress": f"[reference('{route_next_hop}_nic').ipConfigurations[0].properties.privateIPAddress]"
                            }
                        }
                    ]
                },
                "dependsOn": [
                    f"Microsoft.Network/networkInterfaces/{route_next_hop}_nic"
                ]
            })
            self.resources.append({
                "type": "Microsoft.Network/routeTables/routes",
                "apiVersion": "2019-11-01",
                "name": f"{route_name}/{route_name}",
                "dependsOn": [
                    f"[resourceId('Microsoft.Network/routeTables', '{route_name}')]"
                ],
                "properties": {
                    "addressPrefix": route_address_prefix,
                    "nextHopType": "VirtualAppliance",
                    "nextHopIpAddress": f"[reference('{route_next_hop}_nic').ipConfigurations[0].properties.privateIPAddress]"
                }
            })
            subnet_address_prefix = cfg["vnet"]["subnets"][route_subnet]
            self.resources.append({
                "type": "Microsoft.Network/virtualNetworks/subnets",
                "apiVersion": "2019-11-01",
                "name": f"{vnet_name}/{route_subnet}",
                "dependsOn": [
                    f"[resourceId('Microsoft.Network/routeTables', '{route_name}')]"
                ],
                "properties": {
                    "addressPrefix": subnet_address_prefix,
                    "routeTable": {
                        "id": f"[resourceId('Microsoft.Network/routeTables', '{route_name}')]"
                    }
                }
            })

        # vpn gateway 
        vpn_gateway_name = cfg["vnet"]["gateway"].get("name", None)
        if vpn_gateway_name:
            log.info(f"add vpn gateway ({vpn_gateway_name})")
            rrg = cfg["resource_group"]
            vnetname = cfg["vnet"]["name"]
            subnet = cfg["vnet"]["gateway"].get("subnet") 
            aad_tenant = cfg["vnet"]["gateway"].get("aad_tenant") 
            aad_audience = cfg["vnet"]["gateway"].get("aad_audience") 
            aad_issuer = cfg["vnet"]["gateway"].get("aad_issuer") 
            nicdeps = []
            pipname = vpn_gateway_name+"_pip"
            dnsname = azutil.get_dns_label(rrg, pipname, True)
            if dnsname:
                log.debug(f"dns name: {dnsname} (using existing one)")
            else:
                dnsname = vpn_gateway_name+str(uuid.uuid4())[:6]
                log.debug(f"dns name: {dnsname}")

            nicdeps.append("Microsoft.Network/publicIpAddresses/"+pipname)

            pipres = {
                    "type": "Microsoft.Network/publicIPAddresses",
                    "apiVersion": "2018-01-01",
                    "name": pipname,
                    "location": location,
                    "dependsOn": [],
                    "tags": gtags,
                    "properties": {
                        "dnsSettings": {
                            "domainNameLabel": dnsname
                        }
                    }
            }
            self.resources.append(pipres)

            self.resources.append({
                "type": "Microsoft.Network/virtualNetworkGateways",
                "apiVersion": "2020-11-01",
                "name": vpn_gateway_name,
                "tags": gtags,
                "location": location,
                "properties": {
                    "enablePrivateIpAddress": False,
                    "ipConfigurations": [
                        {
                            "name": "default",
                            "properties": {
                                "privateIPAllocationMethod": "Dynamic",
                                "publicIPAddress": {
                                    "id": "[resourceId('Microsoft.Network/publicIPAddresses', '{}')]".format(pipname) 
                                },
                                "subnet": {
                                    "id": "[resourceId('Microsoft.Network/virtualNetworks/subnets', '{}', '{}')]".format(vnetname, subnet)
                                }
                            }
                        }
                    ],
                    "sku": {
                        "name": "VpnGw2",
                        "tier": "VpnGw2"
                     },
                    "gatewayType": "Vpn",
                    "vpnType": "RouteBased",
                    "enableBgp": False,
                    "activeActive": False,
                    "vpnClientConfiguration": {
                        "vpnClientAddressPool": {
                            "addressPrefixes": [
                                "172.0.0.0/24"
                            ]
                        },
                        "vpnClientProtocols": [
                             "OpenVPN"
                        ],
                        "vpnAuthenticationTypes": [
                            "AAD"
                        ],
                        "vpnClientRootCertificates": [],
                        "vpnClientRevokedCertificates": [],
                        "radiusServers": [],
                        "vpnClientIpsecPolicies": [],
                        "aadTenant": aad_tenant,
                        "aadAudience": aad_audience,
                        "aadIssuer": aad_issuer
                     },
                    "bgpSettings": {
                         "asn": 65515,
                         "bgpPeeringAddress": "10.0.4.254",
                         "peerWeight": 0,
                         "bgpPeeringAddresses": [
                             {
                                "ipconfigurationId": "[concat(resourceId('Microsoft.Network/virtualNetworkGateways', '{}'), '/ipConfigurations/default')]".format(vpn_gateway_name),
                                "customBgpIpAddresses": []
                             }
                         ]
                     },
                     "vpnGatewayGeneration": "Generation2"
                  }
            })

    def _add_netapp(self, cfg, name, deploy_network):
        account = cfg["storage"][name]
        loc = cfg["location"]
        vnet = cfg["vnet"]["name"]
        subnet = account["subnet"]
        nicdeps = []
        gtags = cfg.get("global_tags", {})

        rg = cfg["resource_group"]
        vnetrg = cfg["vnet"].get("resource_group", rg)
        if (rg == vnetrg) and deploy_network:
            log.debug("adding delegation to subnet")
            rvnet = next((x for x in self.resources if x["name"] == vnet), [])
            rsubnet = next(
                (x for x in rvnet["properties"]["subnets"] if x["name"] == subnet), None)
            if not rsubnet:
                log.error(
                    "subnet ({}) for netapp storage ({}) does not exist".format(subnet, name))
                sys.exit(1)
            if "delegations" not in rsubnet["properties"]:
                rsubnet["properties"]["delegations"] = []
            rsubnet["properties"]["delegations"].append({
                "properties": {
                    "serviceName": "Microsoft.Netapp/volumes"
                },
                "name": "netappdelegation"
            })

            nicdeps.append("Microsoft.Network/virtualNetworks/"+vnet)
            subnetid = "[resourceId('Microsoft.Network/virtualNetworks/subnets', '{}', '{}')]".format(
                vnet, subnet)
        else:
            subnetid = "[resourceId('{}', 'Microsoft.Network/virtualNetworks/subnets', '{}', '{}')]".format(
                vnetrg, vnet, subnet)

        addomain = account.get("joindomain", None)
        props = {}
        if addomain:
            adip = azutil.get_vm_private_ip(rg, account["ad_server"])
            adpassword = account["ad_password"]
            adusername = account["ad_username"]
            # TODO: previously we used ip address for the dns here
            props["activeDirectories"] = [
                {
                    "username": adusername,
                    "password": adpassword,
                    "domain": addomain,
                    "dns": adip,
                    "smbServerName": "anf"
                }
            ]

        self.resources.append({
            "name": name,
            "type": "Microsoft.NetApp/netAppAccounts",
            "apiVersion": "2020-02-01",
            "tags": gtags,
            "location": loc,
            "properties": props,
            "dependsOn": nicdeps
        })

        for poolname in account.get("pools", {}).keys():
            pool = account["pools"][poolname]
            poolsize = pool["size"]
            servicelevel = pool["service_level"]
            self.resources.append({
                "name": name+"/"+poolname,
                "type": "Microsoft.NetApp/netAppAccounts/capacityPools",
                "apiVersion": "2020-02-01",
                "tags": gtags,
                "location": loc,
                "properties": {
                    "size": poolsize * 2**40,
                    "serviceLevel": servicelevel
                },
                "dependsOn": [
                    "[resourceId('Microsoft.NetApp/netAppAccounts', '{}')]".format(name)
                ],
            })

            for volname in pool.get("volumes", {}).keys():
                vol = pool["volumes"][volname]
                volsize = vol["size"]
                voltype = vol.get("type", "nfs")
                # TODO : Why is this unused ?
                #volmount = vol["mount"]
                netapp_volume = {
                    "name": name+"/"+poolname+"/"+volname,
                    "type": "Microsoft.NetApp/netAppAccounts/capacityPools/volumes",
                    "apiVersion": "2020-06-01",
                    "tags": gtags,
                    "location": loc,
                    "properties": {
                        "creationToken": volname,
                        "serviceLevel": servicelevel,
                        "usageThreshold": volsize * 2**40,
                        "subnetId": subnetid
                    },
                    "dependsOn": [
                        "[resourceId('Microsoft.NetApp/netAppAccounts/capacityPools', '{}', '{}')]".format(
                            name, poolname)
                    ]
                }
                if voltype == "cifs":
                    netapp_volume["properties"]["protocolTypes"] = ["CIFS"]
                    netapp_volume["properties"]["kerberosEnabled"] = "false"

                self.resources.append(netapp_volume)

    def _add_storageaccount(self, cfg, name):
        loc = cfg["location"]
        gtags = cfg.get("global_tags", {})

        res = {
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2019-06-01",
            "name": name,
            "tags": gtags,
            "location": loc,
            "sku": {
                "name": "Standard_LRS"
            },
            "kind": "StorageV2",
            "properties": {
                "accessTier": "Hot"
            },
            "resources": []
        }

        for container in cfg["storage"][name].get("containers", []):
            res["resources"].append(
                {
                    "type": "blobServices/containers",
                    "apiVersion": "2019-06-01",
                    "name": f"default/{container}",
                    "tags": gtags,
                    "dependsOn": [
                        name
                    ]
                }
            )

        self.resources.append(res)

    def _add_proximity_group(self, cfg):
        ppg = cfg.get("proximity_placement_group_name", None)
        gtags = cfg.get("global_tags", {})

        if ppg:
            loc = cfg["location"]
            self.resources.append({
                "apiVersion": "2018-04-01",
                "type": "Microsoft.Compute/proximityPlacementGroups",
                "name": ppg,
                "tags": gtags,
                "location": loc
            })

    def __helper_arm_create_osprofile(self, rname, rtype, adminuser, adminpass, sshkey, customdata):
        if rtype == "vm":
            name = "computerName"
        else:
            name = "computerNamePrefix"

        osprofile = {
            name: rname,
            "adminUsername": adminuser
        }
        if customdata:
            if customdata.startswith("http"):
                customdata = "#include\n" + customdata
            osprofile["customData"] = "[base64('" + customdata + "')]"
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

    def __helper_arm_create_datadisks(self, sizes, sku, cache):
        datadisks = []
        for i, d in enumerate(sizes):
            if d < 4096:
                cacheoption = cache
            else:
                cacheoption = "None"
            
            # To support deploying images that contains datadisks
            createOption = "Empty"
            if d == 0:
                d = ""
                createOption = "fromImage"

            if sku == "UltraSSD_LRS":
                cacheoption = "None"

            datadisks.append({
                "caching": cacheoption,
                "managedDisk": {
                    "storageAccountType": sku
                },
                "createOption": createOption,
                "lun": i,
                "diskSizeGB": d
            })
        return datadisks

    def __helper_arm_create_image_reference(self, refstr):
        if ":" in refstr:
            return {
                "publisher": refstr.split(":")[0],
                "offer": refstr.split(":")[1],
                "sku": refstr.split(":")[2],
                "version": refstr.split(":")[3]
            }
        else:
            return {
                "id": refstr
            }

    def __helper_arm_create_plan(self, refstr):
        if ":" in refstr:
            return {
                "publisher": refstr.split(":")[0],
                "product": refstr.split(":")[1],
                "name": refstr.split(":")[2]
            }
        else:
            return { }

    def __helper_arm_add_zones(self, res, zones):
        strzones = []
        if type(zones) == list:
            for z in zones:
                strzones.append(z)
        elif zones != None:
            strzones.append(str(zones))
        if len(strzones) > 0:
            res["zones"] = strzones

    def _add_vm(self, cfg, r, vnet_in_deployment):
        res = cfg["resources"][r]
        rsshport = cfg.get("ssh_port", 22)
        rtype = res["type"]
        rsize = res["vm_type"]
        rimage = res["image"]
        ros = rimage.split(':')
        rinstances = res.get("instances", 1)
        rpip = res.get("public_ip", False)
        rdns = res.get("dns_name", None)
        rnsgallow = res.get("nsg_allow", None)
        rnsgsourceip = res.get("nsg_source_ip", None)
        rppg = res.get("proximity_placement_group", False)
        rppgname = cfg.get("proximity_placement_group_name", None)
        raz = res.get("availability_zones", None)
        rsubnet = res["subnet"]
        ran = res.get("accelerated_networking", False)
        rlowpri = res.get("low_priority", False)
        rephemeralosdisk = res.get("ephemeral_os_disk", False)
        rephemeralosdiskplacement = res.get("ephemeral_os_disk_placement", "CacheDisk")
        rosdisksize = res.get("os_disk_size", None)
        rosstoragesku = res.get("os_storage_sku", "Premium_LRS")
        rdatadisks = res.get("data_disks", [])
        rstoragesku = res.get("storage_sku", "Premium_LRS")
        rstoragecache = res.get("storage_cache", "ReadWrite")
        gtags = cfg.get("global_tags", {})
        rtags = res.get("resource_tags", {}).copy()
        rtags.update(gtags)
        rmanagedidentity = res.get("managed_identity", None)
        loc = cfg["location"]
        ravset = res.get("availability_set")
        customdata = res.get("custom_data", None)
        adminuser = cfg["admin_user"]
        rrg = cfg["resource_group"]
        vnetname = cfg["vnet"]["name"]
        vnetrg = cfg["vnet"].get("resource_group", rrg)
        if vnet_in_deployment:
            rsubnetid = "[resourceId('Microsoft.Network/virtualNetworks/subnets', '{}', '{}')]".format(
                vnetname, rsubnet)
        else:
            rsubnetid = "[resourceId('{}', 'Microsoft.Network/virtualNetworks/subnets', '{}', '{}')]".format(
                vnetrg, vnetname, rsubnet)
        rpassword = res.get("password", "<no-password>")
        with open(adminuser+"_id_rsa.pub") as f:
            sshkey = f.read().strip()

        if rsshport != 22:
            if customdata:
                log.error("Cannot specify custom data with a non-standard SSH port for VMs with a public IP.")
            customdata = f"#!/bin/bash\nsed -i \"s/^#Port 22/Port 22\\nPort {rsshport}/\" /etc/ssh/sshd_config\nyum install -y policycoreutils-python-utils\nsemanage port -a -t ssh_port_t -p tcp {rsshport}\nsystemctl restart sshd\n"

        if ravset and ravset not in self.avsets:
            arm_avset = {
                "name": ravset,
                "type": "Microsoft.Compute/availabilitySets",
                "apiVersion": "2018-10-01",
                "location": loc,
                "tags": gtags,
                "sku": {
                    "name": "Aligned"
                },
                "properties": {
                    "platformUpdateDomainCount": 1,
                    "platformFaultDomainCount": 1
                }
            }
            if rppg:
                arm_avset["properties"]["proximityPlacementGroup"] = {
                    "id": f"[resourceId('Microsoft.Compute/proximityPlacementGroups','{rppgname}')]"
                }
                arm_avset["dependsOn"] = [
                    f"Microsoft.Compute/proximityPlacementGroups/{rppgname}"
                ]
            self.resources.append(arm_avset)
            self.avsets.add(ravset)

        rorig = r
        for instance in range(1, rinstances+1):
            if rinstances > 1:
                r = "{}{:04}".format(rorig, instance)

            nicdeps = []
            if vnet_in_deployment:
                nicdeps.append("Microsoft.Network/virtualNetworks/"+vnetname)

            if rpip:
                pipname = r+"_pip"
                if rdns:
                    dnsname = rdns
                else:
                    dnsname = azutil.get_dns_label(rrg, pipname, True)
                    if dnsname:
                        log.debug(f"dns name: {dnsname} (using existing one)")
                    else:
                        dnsname = r+str(uuid.uuid4())[:6]
                        log.debug(f"dns name: {dnsname}")
                nsgname = r+"_nsg"

                nicdeps.append("Microsoft.Network/publicIpAddresses/"+pipname)
                nicdeps.append(
                    "Microsoft.Network/networkSecurityGroups/"+nsgname)

                pipres = {
                    "type": "Microsoft.Network/publicIPAddresses",
                    "apiVersion": "2018-01-01",
                    "name": pipname,
                    "location": loc,
                    "dependsOn": [],
                    "tags": gtags,
                    "properties": {
                        "dnsSettings": {
                            "domainNameLabel": dnsname
                        }
                    }
                }
                self.__helper_arm_add_zones(pipres, raz)
                self.resources.append(pipres)

                nsg_security_rules = {
                    "rdp": {
                        "name": "default-allow-rdp",
                        "properties": {
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "3389",
                            "sourceAddressPrefix": "*",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 1000,
                            "direction": "Inbound"
                        }
                    },
                    "ssh":  {
                        "name": "default-allow-ssh",
                        "properties": {
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": str(rsshport),
                            "sourceAddressPrefix": "*",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 1010,
                            "direction": "Inbound"
                        }
                    },
                    "http":  {
                        "name": "default-allow-http",
                        "properties": {
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "80",
                            "sourceAddressPrefix": "*",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 1020,
                            "direction": "Inbound"
                        }
                    },
                    "https":  {
                        "name": "default-allow-https",
                        "properties": {
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "443",
                            "sourceAddressPrefix": "*",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 1030,
                            "direction": "Inbound"
                        }
                    },
                    "grafana":  {
                        "name": "default-allow-grafana",
                        "properties": {
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "3000",
                            "sourceAddressPrefix": "*",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 1040,
                            "direction": "Inbound"
                        }
                    },
                    "zcentral":  {
                        "name": "default-allow-zcentral",
                        "properties": {
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "42966",
                            "sourceAddressPrefix": "*",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 1050,
                            "direction": "Inbound"
                        }
                    }
                }

                if rnsgallow:
                    nsgrules = [ nsg_security_rules[service] for service in rnsgallow ]
                else:
                    if ros[0] == "MicrosoftWindowsServer" or ros[0] == "MicrosoftWindowsDesktop":
                        nsgrules = [ nsg_security_rules["rdp"] ]
                    else:
                        nsgrules = [ nsg_security_rules["ssh"] ]
                if rnsgsourceip:
                    for rule in nsgrules:
                        rule["properties"]["sourceAddressPrefix"] = rnsgsourceip

                self.resources.append({
                    "type": "Microsoft.Network/networkSecurityGroups",
                    "apiVersion": "2015-06-15",
                    "name": nsgname,
                    "location": loc,
                    "dependsOn": [],
                    "tags": gtags,
                    "properties": {
                            "securityRules": nsgrules
                    }
                })

            nicname = r+"_nic"
            ipconfigname = r+"_ipconfig"
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
                "tags": gtags,
                "properties": nicprops
            })

            osprofile = self.__helper_arm_create_osprofile(
                r, rtype, adminuser, rpassword, sshkey, customdata)
            datadisks = self.__helper_arm_create_datadisks(
                rdatadisks, rstoragesku, rstoragecache)
            imageref = self.__helper_arm_create_image_reference(rimage)

            deps = [f"Microsoft.Network/networkInterfaces/{nicname}"]
            if rppg:
                deps.append(
                    f"Microsoft.Compute/proximityPlacementGroups/{rppgname}")
            if ravset:
                deps.append(f"Microsoft.Compute/availabilitySets/{ravset}")

            # Add support for cyclecloud/azhpc plan
            plan = ""
            if ros[0] == "azurecyclecloud" or ros[0] == "azhpc" or ros[0] == "almalinux":
                plan = self.__helper_arm_create_plan(rimage)
            
            if rephemeralosdisk == True:
                osdisk = {
                    "diffDiskSettings": {
                        "option": "Local",
                        "placement": rephemeralosdiskplacement
                    },
                    "caching": "ReadOnly",
                    "createOption": "FromImage"
                }
            else:
                osdisk = {
                    "name": f"{r}_osdisk",
                    "createOption": "fromImage",
                    "caching": "ReadWrite",
                    "managedDisk": {
                        "storageAccountType": rosstoragesku
                    }
                }

            vmres = {
                "type": "Microsoft.Compute/virtualMachines",
                "apiVersion": "2020-06-01",
                "name": r,
                "location": loc,
                "plan": plan,
                "dependsOn": deps,
                "tags": rtags,
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
                        "osDisk": osdisk,
                        "imageReference": imageref,
                        "dataDisks": datadisks
                    },
                    "osProfile": osprofile
                }
            }

            if rlowpri:
                vmres["properties"]["priority"] = "Spot"
                vmres["properties"]["evictionPolicy"] = "Deallocate"

            if rppg:
                vmres["properties"]["proximityPlacementGroup"] = {
                    "id": f"[resourceId('Microsoft.Compute/proximityPlacementGroups','{rppgname}')]"
                }

            if rstoragesku == "UltraSSD_LRS":
                vmres["properties"]["additionalCapabilities"] = {
                    "ultraSSDEnabled": True}

            if ravset:
                vmres["properties"]["availabilitySet"] = {
                    "id": f"[resourceId('Microsoft.Compute/availabilitySets','{ravset}')]"
                }

            if rosdisksize:
                vmres["properties"]["storageProfile"]["osDisk"]["diskSizeGb"] = rosdisksize

            if rmanagedidentity is not None:
                vmres["identity"] = {
                    "type": "SystemAssigned"
                }

                role_lookup = {
                    "reader": "[resourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')]",
                    "contributor": "[resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')]",
                    "owner": "[resourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')]"
                }
                role = rmanagedidentity.get("role", "reader")
                if role not in role_lookup:
                    log.error(
                        f"{role} is an invalid role for a managed identity (options are: {', '.join(role_lookup.keys())})")
                    sys.exit(1)

                scope_lookup = {
                    "resource_group": "[resourceGroup().id]",
                    "subscription": "[subscription().subscriptionId]"
                }
                scope = rmanagedidentity.get("scope", "resource_group")
                if scope not in scope_lookup:
                    log.error(
                        f"{scope} is an invalid scope for a managed identity (options are: {', '.join(scope_lookup.keys())})")
                    sys.exit(1)

                self.resources.append({
                    "apiVersion": "2017-09-01",
                    "type": "Microsoft.Authorization/roleAssignments",
                    "name": f"[guid(subscription().subscriptionId, resourceGroup().id, '{r}')]",
                    "properties": {
                        "roleDefinitionId": role_lookup[role],
                        "principalId": f"[reference('{r}', '2017-12-01', 'Full').identity.principalId]",
                        "scope": scope_lookup[scope]
                    },
                    "dependsOn": [
                        f"[resourceId('Microsoft.Compute/virtualMachines/', '{r}')]"
                    ]
                })

            self.__helper_arm_add_zones(vmres, raz)
            self.resources.append(vmres)

    def _add_vmss(self, cfg, r, vnet_in_deployment):
        res = cfg["resources"][r]
        rtype = res["type"]
        rsize = res["vm_type"]
        rimage = res["image"]
        ros = rimage.split(':')
        rinstances = res.get("instances")
        rppg = res.get("proximity_placement_group", False)
        rppgname = cfg.get("proximity_placement_group_name", None)
        raz = res.get("availability_zones", None)
        rfaultdomaincount = res.get("fault_domain_count", 1)
        rsingleplacementgroup = res.get("single_placement_group", True)
        roverprovision = res.get("overprovision", True)
        rsubnet = res["subnet"]
        ran = res.get("accelerated_networking", False)
        rlowpri = res.get("low_priority", False)
        rephemeralosdisk = res.get("ephemeral_os_disk", False)
        rephemeralosdiskplacement = res.get("ephemeral_os_disk_placement", "CacheDisk")
        rosdisksize = res.get("os_disk_size", None)
        rosstoragesku = res.get("os_storage_sku", "Premium_LRS")
        rdatadisks = res.get("data_disks", [])
        rstoragesku = res.get("storage_sku", "Premium_LRS")
        rstoragecache = res.get("storage_cache", "ReadWrite")
        customdata = res.get("custom_data", None)
        loc = cfg["location"]
        adminuser = cfg["admin_user"]
        rrg = cfg["resource_group"]
        gtags = cfg.get("global_tags", {})
        rtags = res.get("resource_tags", {}).copy()
        rtags.update(gtags)
        rmanagedidentity = res.get("managed_identity", None)
        vnetname = cfg["vnet"]["name"]
        vnetrg = cfg["vnet"].get("resource_group", rrg)
        if vnet_in_deployment:
            rsubnetid = "[resourceId('Microsoft.Network/virtualNetworks/subnets', '{}', '{}')]".format(
                vnetname, rsubnet)
        else:
            rsubnetid = "[resourceId('{}', 'Microsoft.Network/virtualNetworks/subnets', '{}', '{}')]".format(
                vnetrg, vnetname, rsubnet)
        rpassword = res.get("password", "<no-password>")
        with open(adminuser+"_id_rsa.pub") as f:
            sshkey = f.read().strip()

        deps = []
        if vnet_in_deployment:
            deps.append("Microsoft.Network/virtualNetworks/"+vnetname)
        if rppg:
            deps.append("Microsoft.Compute/proximityPlacementGroups/"+rppgname)

        osprofile = self.__helper_arm_create_osprofile(
            r, rtype, adminuser, rpassword, sshkey, customdata)
        datadisks = self.__helper_arm_create_datadisks(
            rdatadisks, rstoragesku, rstoragecache)
        imageref = self.__helper_arm_create_image_reference(rimage)

        # Add support for cyclecloud/azurehpc plan
        plan = ""
        if ros[0] == "azurecyclecloud" or ros[0] == "azhpc" or ros[0] == "almalinux":
            plan = self.__helper_arm_create_plan(rimage)

        if rephemeralosdisk == True:
            osdisk = {
                "diffDiskSettings": {
                    "option": "Local",
                    "placement": rephemeralosdiskplacement
                },
                "caching": "ReadOnly",
                "createOption": "FromImage"
            }
        else:
            osdisk = {
                "createOption": "FromImage",
                "caching": "ReadWrite",
                "managedDisk": {
                    "storageAccountType": rosstoragesku
                }
            }
        
        nicname = r+"_nic"
        ipconfigname = r+"_ipconfig"
        vmssres = {
            "type": "Microsoft.Compute/virtualMachineScaleSets",
            "apiVersion": "2020-06-01",
            "name": r,
            "location": loc,
            "plan": plan,
            "dependsOn": deps,
            "tags": rtags,
            "sku": {
                "name": rsize,
                "capacity": rinstances
            },
            "properties": {
                "overprovision": roverprovision,
                "upgradePolicy": {
                    "mode": "manual"
                },
                "virtualMachineProfile": {
                    "storageProfile": {
                        "osDisk": osdisk,
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
                "singlePlacementGroup": rsingleplacementgroup
            }
        }

        if rfaultdomaincount:
            vmssres["properties"]["platformFaultDomainCount"] = rfaultdomaincount

        if rppg:
            vmssres["properties"]["proximityPlacementGroup"] = {
                "id": "[resourceId('Microsoft.Compute/proximityPlacementGroups','{}')]".format(rppgname)
            }
        
        if rstoragesku == "UltraSSD_LRS":
            vmssres["properties"]["additionalCapabilities"] = {
                "ultraSSDEnabled": True
            }

        if rlowpri:
            vmssres["properties"]["virtualMachineProfile"]["priority"] = "Spot"
            vmssres["properties"]["virtualMachineProfile"]["evictionPolicy"] = "Delete"

        if rosdisksize:
            vmssres["properties"]["virtualMachineProfile"]["storageProfile"]["osDisk"]["diskSizeGb"] = rosdisksize

        if rmanagedidentity is not None:
            vmssres["identity"] = {
                "type": "SystemAssigned"
            }

            role_lookup = {
                "reader": "[resourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')]",
                "contributor": "[resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')]",
                "owner": "[resourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')]"
            }
            role = rmanagedidentity.get("role", "reader")
            if role not in role_lookup:
                log.error(
                    f"{role} is an invalid role for a managed identity (options are: {', '.join(role_lookup.keys())})")
                sys.exit(1)

            scope_lookup = {
                "resource_group": "[resourceGroup().id]",
                "subscription": "[subscription().subscriptionId]"
            }
            scope = rmanagedidentity.get("scope", "resource_group")
            if scope not in scope_lookup:
                log.error(
                    f"{scope} is an invalid scope for a managed identity (options are: {', '.join(scope_lookup.keys())})")
                sys.exit(1)

            self.resources.append({
                "apiVersion": "2017-09-01",
                "type": "Microsoft.Authorization/roleAssignments",
                "name": f"[guid(subscription().subscriptionId, resourceGroup().id, '{r}')]",
                "tags": gtags,
                "properties": {
                    "roleDefinitionId": role_lookup[role],
                    "principalId": f"[reference('{r}', '2017-12-01', 'Full').identity.principalId]",
                    "scope": scope_lookup[scope]
                },
                "dependsOn": [
                    f"[resourceId('Microsoft.Compute/virtualMachineScaleSets/', '{r}')]"
                ]
            })

        self.__helper_arm_add_zones(vmssres, raz)
        self.resources.append(vmssres)

    def read_resources(self, cfg, vnet_in_deployment):
        resources = cfg.get("resources", {})
        for r in resources.keys():
            rtype = cfg["resources"][r]["type"]
            if rtype == "vm":
                self._add_vm(cfg, r, vnet_in_deployment)
            elif rtype == "vmss":
                self._add_vmss(cfg, r, vnet_in_deployment)
            elif rtype == "slurm_partition":
                pass
            else:
                log.error(
                    "unrecognised resource type ({}) for {}".format(rtype, r))

    def has_resources(self):
        return len(self.resources) > 0

    def read(self, cfg, deploy_network):
        rg = cfg["resource_group"]
        vnetrg = cfg["vnet"].get("resource_group", rg)

        vnet_in_deployment = bool(rg == vnetrg) and deploy_network

        if deploy_network:
            self._add_network(cfg)
        self._add_proximity_group(cfg)
        self.read_resources(cfg, vnet_in_deployment)

        storage = cfg.get("storage", {})
        for s in storage.keys():
            stype = cfg["storage"][s]["type"]
            if stype == "anf":
                self._add_netapp(cfg, s, deploy_network)
            elif stype == "storageaccount":
                self._add_storageaccount(cfg, s)
            else:
                log.error(
                    "unrecognised storage type ({}) for {}".format(stype, s))

    def to_json(self):
        return json.dumps({
            "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "parameters": self.parameters,
            "variables": self.variables,
            "resources": self.resources,
            "outputs": self.outputs
        }, indent=4)

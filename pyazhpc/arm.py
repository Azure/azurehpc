import json

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
                }
            },
            "resources": []
        }

        subnets = cfg["vnet"]["subnets"]
        for subnet_name in subnets:
            subnet_address_prefix = cfg["vnet"]["subnets"][subnet_name]
            res["resources"].append({
                "apiVersion": "2018-10-01",
                "type": "subnets",
                "location": location,
                "name": subnet_name,
                "dependsOn": [
                    vnet_name
                ],
                "properties": {
                    "addressPrefix": subnet_address_prefix
                }
            })

        self.resources.append(res)

    def _read_vm(self, cfg, r):
        res = cfg["resources"][r]
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
        #r = res["os_storage_sku"]
        #r = res[""]

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
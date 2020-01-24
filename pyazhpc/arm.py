import json

import azconfig

class ArmTemplate:
    def __init__(self):
        self.parameters = {}
        self.variables = {}
        self.resources = []
        self.outputs = {}
    
    def _read_network(self, cfg):
        location = cfg.read_value("location")
        vnet_name = cfg.read_value("vnet.name")
        address_prefix = cfg.read_value("vnet.address_prefix")
        
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

        subnets = cfg.read_keys("vnet.subnets")
        for subnet_name in subnets:
            subnet_address_prefix = cfg.read_value("vnet.subnets."+subnet_name)
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

    def read(self, cfg):
        self._read_network(cfg)

    def to_json(self):
        return json.dumps({
            "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "parameters": self.parameters,
            "variables": self.variables,
            "resources": self.resources,
            "outputs": self.outputs
        }, indent=4)
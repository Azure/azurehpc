import json

class ArmTemplate:
    def __init__(self):
        self.parameters = {}
        self.variables = {}
        self.resources = []
        self.outputs = {}
    
    def to_json(self):
        return json.dumps({
            "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "parameters": self.parameters,
            "variables": self.variables,
            "resources": self.resources,
            "outputs": self.outputs
        }, indent=4)
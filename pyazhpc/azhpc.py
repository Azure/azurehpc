import argparse
import json
import pprint
import arm

def create_arm_template():
    return {
        "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {},
        "variables": {},
        "resources": [],
        "outputs": {}
    }

parser = argparse.ArgumentParser()
parser.add_argument("filename", type=str, help="config file")
args = parser.parse_args()

tpl = arm.ArmTemplate()

print(tpl.to_json())

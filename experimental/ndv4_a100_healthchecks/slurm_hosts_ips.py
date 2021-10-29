#!/usr/bin/env python

# Gets a list of SLURM nodenames and corresponding IP addresses

import subprocess
import re
import os
import shutil

cmd="scontrol show node"

output = subprocess.check_output(cmd, shell=True)

nodes = output.decode("utf-8").split("\n\n")

for node in nodes:
    results = dict(re.findall(r'(\w*)=(\".*?\"|\S*)', node))
    if "NodeName" in results and "NodeAddr" in results and results["NodeName"] != results["NodeAddr"]:
        print("{} {}".format(results["NodeAddr"],results["NodeName"]))

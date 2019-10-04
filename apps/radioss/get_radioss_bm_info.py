#!/bin/env python3
  
import argparse
from subprocess import Popen, PIPE
import json
import pprint
import statistics as stat
import os, sys

parser = argparse.ArgumentParser(prog='PROG', usage='%(prog)s [options]')
parser.add_argument("-m", type=str, help="-m <model name>")
parser.add_argument("-f", type=str, help="-f <file name>")
args = parser.parse_args()

filename=""
if args.m != None:
    print("Model Name: {}".format(args.m))
    filename="{}_00001.out".format(args.m)
if args.f != None:
#    print("File Name: {}".format(args.f))
    filename="{}".format(args.f)

# Read file and collect data
data = {}
data["procs_cpu"] = []
with open(filename) as rst:
    lines=rst.readlines()
    try:
        data["Model"] = lines[0][:-10]
    except:
        sys.exit(-1)
    for i,line in enumerate(lines):
        if line.find("NUMBER OF SPMD DOMAINS") != -1:
            sline = line.split()
#            print("Sline: {}".format(sline))
            data["NumOfSpmdDomains"] = sline[-1]
        elif line.find("NUMBER OF THREADS PER DOMAIN") != -1:
            sline = line.split()
#            print("Sline: {}".format(sline))
            data["NumOfThreadsPerDomain"] = sline[-1]
        elif line.find("ELAPSED TIME") != -1:
            sline = line.split()
#            print("Sline: {}".format(sline))
            data["ElapsedTime"] = sline[-2]
        elif line.find("ESTIMATED SPEEDUP") != -1:
            sline = line.split()
#            print("Sline: {}".format(sline))
            data["EstimatedSpeedUp"] = line.split()[-1]
        elif line.find("** SPMD COMM. TIME **") != -1:
            nlines = lines[i:]
            for nline in nlines:
                if nline.find("** CUMULATIVE CPU TIME SUMMARY **") == -1:
                    sline = nline.split()
                    if len(sline) > 0:
#                        print("Sline: {}".format(sline))
                        if len(sline) == 7:
                            data["procs_cpu"].append(float(sline[-1]))
                else:
                    break
                  
            
#    print("Data: {}".format(data))

# Add json data
try:
    jdata = {}
    jdata["model"] = data["Model"]
    jdata["total_time"] = data["ElapsedTime"]
    jdata["num_of_spmd_domains"] = data["NumOfSpmdDomains"]
    jdata["num_of_threads_per_domain"] = data["NumOfThreadsPerDomain"]
    jdata["est_speed_up"] = data["EstimatedSpeedUp"]
    jdata["cpu_mean"] = "{:2.3}".format(stat.mean(data["procs_cpu"]))
    jdata["cpu_max"] = "{:2.3}".format(max(data["procs_cpu"]))
    jdata["cpu_min"] = "{:2.3}".format(min(data["procs_cpu"]))
    jdata["cpu_stdev"] = "{:2.3}".format(stat.stdev(data["procs_cpu"]))
    #jdata = json.dumps(jdata)
#    pprint.pprint(jdata)
except:
    sys.exit(-1)

if args.m != None:
    with open('{}_results.json'.format(data["Model"].strip()), 'w') as f:
        json.dump(jdata, f, indent=4, separators=(',', ': '), sort_keys=True)

print(
    "{:>20}".format(data["Model"]), \
    "{:>10}".format(data["ElapsedTime"]), \
    "{:>10}".format(data["NumOfSpmdDomains"]), \
    "{:>10}".format(data["NumOfThreadsPerDomain"]), \
    "{:>10}".format(data["EstimatedSpeedUp"]), \
    "{:>10.2f}".format(stat.mean(data["procs_cpu"])), \
    "{:>10.2f}".format(max(data["procs_cpu"])), \
    "{:>10.2f}".format(min(data["procs_cpu"])), \
    "{:>10.2f}".format(stat.stdev(data["procs_cpu"]))
)

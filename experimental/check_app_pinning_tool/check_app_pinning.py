#!/usr/bin/python3

import subprocess
import sys
import os
import re
import argparse
import itertools
import socket
import json
from urllib.request import urlopen, Request

l3cache_coreid_d = {"Standard_HB120rs_v3": {"l3cache_ids": {0: [0,1,2,3,4,5,6,7],\
                                                           1: [8,9,10,11,12,13,14,15],\
                                                           2: [16,17,18,19,20,21,22,23],\
                                                           3: [24,25,26,27,28,29],\
                                                           4: [30,31,32,33,34,35,36,37],\
                                                           5: [38,39,40,41,42,43,44,45],\
                                                           6: [46,47,48,49,50,51,52,53],\
                                                           7: [54,55,56,57,58,59],\
                                                           8: [60,61,62,63,64,65,66,67],\
                                                           9: [68,69,70,71,72,73,74,75],\
                                                          10: [76,77,78,79,80,81,82,83],\
                                                          11: [84,85,86,87,88,89],\
                                                          12: [90,91,92,93,94,95,96,97],\
                                                          13: [98,99,100,101,102,103,104,105],\
                                                          14: [106,107,108,109,110,111,112,113],\
                                                          15: [114,115,116,117,118,119]\
                                                          },
                                          "allowed_number_of_processes": [16,32,48,64,80,96,120],
                                          "excluded_cores": {6: [6,7,14,15,22,23,36,37,44,45,52,53,66,67,74,75,82,83,96,97,104,105,112,113],
                                                            5: [5,6,7,13,14,15,21,22,23,29,35,36,37,43,44,45,50,51,52,53,59,65,66,67,73,74,75,81,82,83,89,95,96,97,103,104,105,111,112,113,119],
                                                            4: [4,5,6,7,12,13,14,15,20,21,22,23,28,29,34,35,36,37,42,43,44,45,49,50,51,52,53,58,59,64,65,66,67,72,73,74,75,80,81,82,83,88,89,94,95,96,97,102,103,104,105,110,111,112,113,118,119],
                                                            3: [3,4,5,6,7,11,12,13,14,15,19,20,21,22,23,27,28,29,33,34,35,36,37,41,42,43,44,45,48,49,50,51,52,53,57,58,59,63,64,65,66,67,71,72,73,74,75,79,80,81,82,83,87,88,89,93,94,95,96,97,101,102,103,104,105,109,110,111,112,113,117,118,119],
                                                            2: [2,3,4,5,6,7,10,11,12,13,14,15,18,19,20,21,22,23,26,27,28,29,32,33,34,35,36,37,40,41,42,43,44,45,47,48,49,50,51,52,53,56,57,58,59,62,63,64,65,66,67,70,71,72,73,74,75,78,79,80,81,82,83,86,87,88,89,92,93,94,95,96,97,100,101,102,103,104,105,108,109,110,111,112,113,116,117,118,119],
                                          }},
                    "Standard_HB120-96rs_v3": {"l3cache_ids":  {0: [0,1,2,3,4,5],\
                                                                1: [6,7,8,9,10,11],\
                                                                2: [12,13,14,15,16,17],\
                                                                3: [18,19,20,21,22,23],\
                                                                4: [24,25,26,27,28,29],\
                                                                5: [30,31,32,33,34,35],\
                                                                6: [36,37,38,39,40,41],\
                                                                7: [42,43,44,45,46,47],\
                                                                8: [48,49,50,51,52,53],\
                                                                9: [54,55,56,57,58,59],\
                                                               10: [60,61,62,63,64,65],\
                                                               11: [66,67,68,69,70,71],\
                                                               12: [72,73,74,75,76,77],\
                                                               13: [78,79,80,81,82,83],\
                                                               14: [84,85,86,87,88,89],\
                                                               15: [90,91,92,93,94,95]\
                                                          },
                                          "allowed_number_of_processes": [16,32,48,64,80,96]
                                           },
                    "Standard_HB120-64rs_v3": {"l3cache_ids":  {0: [0,1,2,3],\
                                                                1: [4,5,6,7],\
                                                                2: [8,9,10,11],\
                                                                3: [12,13,14,15],\
                                                                4: [16,17,18,19],\
                                                                5: [20,21,22,23],\
                                                                6: [24,25,26,27],\
                                                                7: [28,29,30,31],\
                                                                8: [32,33,34,35],\
                                                                9: [36,37,38,39],\
                                                               10: [40,41,42,43],\
                                                               11: [44,45,46,47],\
                                                               12: [48,49,50,51],\
                                                               13: [52,53,54,55],\
                                                               14: [56,57,58,59],\
                                                               15: [60,61,62,63]\
                                                          },
                                          "allowed_number_of_processes": [16,32,48,64]
                                            },
                    "Standard_HB120-32rs_v3": {"l3cache_ids":  {0: [0,1],\
                                                                1: [2,3],\
                                                                2: [4,5],\
                                                                3: [6,7],\
                                                                4: [8,9],\
                                                                5: [10,11],\
                                                                6: [12,13],\
                                                                7: [14,15],\
                                                                8: [16,17],\
                                                                9: [18,19],\
                                                               10: [20,21],\
                                                               11: [22,23],\
                                                               12: [24,25],\
                                                               13: [26,27],\
                                                               14: [28,29],\
                                                               15: [30,31]\
                                                          },
                                        "allowed_number_of_processes": [16,32]
                                          },
                    "Standard_HB120-16rs_v3": {"l3cache_ids":  {0: [0],\
                                                                1: [1],\
                                                                2: [2],\
                                                                3: [3],\
                                                                4: [4],\
                                                                5: [5],\
                                                                6: [6],\
                                                                7: [7],\
                                                                8: [8],\
                                                                9: [9],\
                                                               10: [10],\
                                                               11: [11],\
                                                               12: [12],\
                                                               13: [13],\
                                                               14: [14],\
                                                               15: [15]\
                                                          },
                                         "allowed_number_of_processes": [16]
                                         },
                    "Standard_HB120rs_v2": {"l3cache_ids":  {0: [0,1,2],\
                                                             1: [3,4,5],\
                                                             2: [6,7,8,9],\
                                                             3: [10,11,12,13],\
                                                             4: [14,15,16,17],\
                                                             5: [18,19,20,21],\
                                                             6: [22,23,24,25],\
                                                             7: [26,27,28,29],\
                                                             8: [30,31,32],\
                                                             9: [33,34,35],\
                                                            10: [36,37,38,39],\
                                                            11: [40,41,42,43],\
                                                            12: [44,45,46,47],\
                                                            13: [48,49,50,51],\
                                                            14: [52,53,54,55],\
                                                            15: [56,57,58,59],\
                                                            16: [60,61,62],\
                                                            17: [63,64,65],\
                                                            18: [66,67,68,69],\
                                                            19: [70,71,72,73],\
                                                            20: [74,75,76,77],\
                                                            21: [78,79,80,81],\
                                                            22: [82,83,84,85],\
                                                            23: [86,87,88,89],\
                                                            24: [90,91,92],\
                                                            25: [93,94,95],\
                                                            26: [96,97,98,99],\
                                                            27: [100,101,102,103],\
                                                            28: [104,105,106,107],\
                                                            29: [108,109,110,111],\
                                                            30: [112,113,114,115],\
                                                            31: [116,117,118,119],\
                                                          },
                                                "allowed_number_of_processes": [32,64,96,120]
                                                 },
                    "Standard_HB60rs": {"l3cache_ids":  {0: [0,1,2,3],\
                                                         1: [4,5,6,7],\
                                                         2: [8,9,10,11],\
                                                         3: [12,13,14,15],\
                                                         4: [16,17,18,19],\
                                                         5: [20,21,22,23],\
                                                         6: [24,25,26,27],\
                                                         7: [28,29,30,31],\
                                                         8: [32,33,34,35],\
                                                         9: [36,37,38,39],\
                                                        10: [40,41,42,43],\
                                                        11: [44,45,46,47],\
                                                        12: [48,49,50,51],\
                                                        13: [52,53,54,55],\
                                                        14: [56,57,58,59],\
                                                          },
                                                "allowed_number_of_processes": [15,30,45,60]
                                                 },
                    "Standard_HC44rs": {"l3cache_ids":  {0: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21],\
                                                         1: [22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43],\
                                                          },
                                                "allowed_number_of_processes": [2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44]
                                                 },
                    "Standard_ND96asr_v4": {"l3cache_ids":  {0: [0,1,2,3],\
                                                             1: [4,5,6,7],\
                                                             2: [8,9,10,11],\
                                                             3: [12,13,14,15],\
                                                             4: [16,17,18,19],\
                                                             5: [20,21,22,23],\
                                                             6: [24,25,26,27],\
                                                             7: [28,29,30,31],\
                                                             8: [32,33,34,35],\
                                                             9: [36,37,38,39],\
                                                            10: [40,41,42,43],\
                                                            11: [44,45,46,47],\
                                                            12: [48,49,50,51],\
                                                            13: [52,53,54,55],\
                                                            14: [56,57,58,59],\
                                                            15: [60,61,62,63],\
                                                            16: [64,65,66,67],\
                                                            17: [68,69,70,71],\
                                                            18: [72,73,74,75],\
                                                            19: [76,77,78,79],\
                                                            20: [80,81,82,83],\
                                                            21: [84,85,86,87],\
                                                            22: [88,89,90,91],\
                                                            23: [92,93,94,95]\
                                                          },
                                                "allowed_number_of_processes": [24,48,72,96]
                                                 }}


def get_vm_metadata():
    metadata_url = "http://169.254.169.254/metadata/instance?api-version=2017-08-01"
    metadata_req = Request(metadata_url, headers={"Metadata": True})

    for _ in range(30):
        metadata_response = urlopen(metadata_req, timeout=2)

        try:
            return json.load(metadata_response)
        except ValueError as e:
            print("Failed to get metadata %s" % e)
            print("    Retrying")
            sleep(2)
            continue
        except:
            print("Unable to obtain metadata after 30 tries")
            raise


def one_numa(row_l):
    oneNuma = True
    for row in row_l:
        if "NUMANode" in str(row):
           oneNuma = False
           break
    return oneNuma


def parse_lstopo():
   cmd = ["lstopo-no-graphics", "--no-caches", "--taskset", "--whole-io"]
   try:
      cmdpipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
   except FileNotFoundError:
      print("Error: Could not find the executable (lstopo-on-graphics), make sure you have installed the hwloc package.")
      sys.exit(1)
   topo_d = {}
   topo_d["numanode_ids"] = {}

   row_l = cmdpipe.stdout.readlines()
   if one_numa(row_l):
      numanode = 0
      topo_d["numanode_ids"][numanode] = {}
      topo_d["numanode_ids"][numanode]["core_ids"] = []
      topo_d["numanode_ids"][numanode]["gpu_ids"] = []

   for row in row_l:
       row_s = str(row)
       if "NUMANode" in row_s:
          row_l = row_s.split()
          numanode = int(row_l[2][2:])
          numanode_mask = row_l[-1].split("=")[1][:-3]
          topo_d["numanode_ids"][numanode] = {}
          topo_d["numanode_ids"][numanode]["core_ids"] = []
          topo_d["numanode_ids"][numanode]["gpu_ids"] = []
          topo_d["numanode_ids"][numanode]["mask"] = numanode_mask
       if "Core" in row_s:
          row_l = row_s.split()
          core_id = re.findall(r'\d+',row_l[-2])[0]
          topo_d["numanode_ids"][numanode]["core_ids"].append(int(core_id))
       if re.search(r' {10,}GPU.*card', row_s):
          row_l = row_s.split()
          gpu_id = re.findall(r'\d+',row_l[-1])[0]
          topo_d["numanode_ids"][numanode]["gpu_ids"].append(int(gpu_id)-1)
   cmdpipe.stdout.close()
   cmdpipe.stderr.close()
   return topo_d


def parse_nvidia_smi(number_gpus, process_d):
    process_d["extra_gpu_pids"] = []
    for pid in process_d["pids"]:
        process_d["pids"][pid]["gpu_id"] = "None"
    for gpu_id in range(0, number_gpus):
        cmd = ["nvidia-smi", "--id={}".format(gpu_id), "--query-compute-apps=pid", "--format=csv,noheader"]
        try:
           cmdpipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except FileNotFoundError:
           print("Error: Could not find the executable (nvidia-smi), make sure you have installed the Nvidia GPU driver.")
           sys.exit(1)
        gpu_pid_l = cmdpipe.stdout.readlines()
        for gpu_pid in gpu_pid_l:
            if int(gpu_pid) in process_d["pids"]:
               process_d["pids"][int(gpu_pid)]["gpu_id"] = gpu_id
            else: 
               process_d["extra_gpu_pids"].append(gpu_id)


def create_l3cache_topo(actual_sku_name):
    l3cache_topo_d = {}
    for sku_name in l3cache_coreid_d:
        if sku_name == actual_sku_name:
           l3cache_topo_d = l3cache_coreid_d[sku_name]
           break

    return l3cache_topo_d


def find_pids(pattern):
   cmd = ["pgrep","-f",pattern]
   this_pid=os.getpid()
   this_pid_n = bytes(str(this_pid) + '\n','utf-8')
   pids_l = []
   cmdpipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
   bpids_l = cmdpipe.stdout.readlines()
   if this_pid_n in bpids_l: bpids_l.remove(this_pid_n)
   if not bpids_l:
      print("Error: Cannot find application ({}), check that it is running.".format(pattern))
      sys.exit(1)
   for bpid in  bpids_l:
       pids_l.append(int(bpid))
   return pids_l


def find_threads(pids_l):
   process_d = {}
   process_d["pids"] = {}
   for pid in pids_l:
       process_d["pids"][pid] = {}
       threads_l = os.listdir(os.path.join("/proc",str(pid),"task"))
       nrthreads = find_running_threads(pid, threads_l)
       filepath = os.path.join("/proc",str(pid),"status")
       f = open(filepath)
       for line in f:
           if "Threads" in line:
              num_threads = line.split(":")[1].strip()
              process_d["pids"][pid]["num_threads"] = num_threads
              process_d["pids"][pid]["running_threads"] = nrthreads
           if "Cpus_allowed_list" in line:
              cpus_allowed = line.split(":")[1].strip()
              process_d["pids"][pid]["cpus_allowed"] = cpus_allowed
   return process_d


def find_gpus_in_numa(numa_id, topo_d):
   for numanode_id in topo_d["numanode_ids"]:
      if numa_id == numanode_id:
         return topo_d["numanode_ids"][numanode_id]["gpu_ids"]
   

def find_process_gpus(topo_d, process_d):
   for pid in process_d["pids"]:
      all_gpus_l = []
      for numa_id in process_d["pids"][pid]["numas"]:
         gpus_l = find_gpus_in_numa(numa_id, topo_d)
         all_gpus_l.extend(gpus_l)
      process_d["pids"][pid]["gpus_in_numas"] = all_gpus_l


def find_last_core_id(process_d): 
   for pid in process_d["pids"]:
       filepath = os.path.join("/proc",str(pid),"stat")
       f = open(filepath)
       for line in f:
           last_core_id = line.split()[38]
       process_d["pids"][pid]["last_core_id"] = last_core_id
   

def conv_indx_str_to_list(indx_str):
   if "," in indx_str:
      parts = indx_str.split(",")
   else:
      parts = [indx_str]
   indx_l = []
   for part in parts:
      if "-" in part:
         indx_str_l = part.split("-")
         indx_l += list(range(int(indx_str_l[0]),int(indx_str_l[1])+1))
      else:
         indx_l.append(int(part))
   return indx_l


def find_numas(cpus_allowed, topo_d):
   numa_l = []
   cpus_l = conv_indx_str_to_list(cpus_allowed)
   for cpu in cpus_l:
       for numa_id in topo_d["numanode_ids"]:
          core_id_l = topo_d["numanode_ids"][numa_id]["core_ids"]
          if cpu in core_id_l:
             numa_l.append(int(numa_id))
   return (list(set(numa_l)),len(cpus_l))


def find_process_numas(topo_d, process_d):
   for pid in process_d["pids"]:
       cpus_allowed = process_d["pids"][pid]["cpus_allowed"]
       numa_l,lenc = find_numas(cpus_allowed, topo_d)
       process_d["pids"][pid]["numas"] = numa_l
       process_d["pids"][pid]["num_core_ids"] = lenc


def find_running_threads(pid, threads_l):
    nrthreads = 0
    for thread in threads_l:
        filepath = os.path.join("/proc",str(pid),"task",thread,"status")
        f = open(filepath)
        for line in f:
           if "running" in line:
              nrthreads += 1
              break
    return nrthreads


def check_if_sku_is_supported(actual_sku_name):
    sku_found = False
    supported_sku_names_l = []
    for sku_name in l3cache_coreid_d:
        supported_sku_names_l.append(sku_name)
        if sku_name == actual_sku_name:
           sku_found = True
           break
    
    return (sku_found,supported_sku_names_l)


def calc_total_num_processes(process_d):
   return len(process_d["pids"])


def calc_total_num_gpus(topo_d):
   num_gpus = 0
   for numanode in topo_d["numanode_ids"]:
      num_gpus += len(topo_d["numanode_ids"][numanode]["gpu_ids"])

   return num_gpus


def calc_total_num_numas(topo_d):
   return len(topo_d["numanode_ids"])


def calc_total_num_l3caches(l3cache_topo_d):
   if l3cache_topo_d:
      return len(l3cache_topo_d["l3cache_ids"])
   else:
      return 0


def calc_total_num_cores(topo_d):
   total_num_cores = 0
   for numnode_id in topo_d["numanode_ids"]:
      core_ids_l = topo_d["numanode_ids"][numnode_id]["core_ids"]
      c = len(core_ids_l)
      total_num_cores += len(core_ids_l)

   return  total_num_cores


def calc_total_num_threads(process_d):
   total_num_threads = 0
   for pid in process_d["pids"]:
      total_num_threads += process_d["pids"][pid]["running_threads"]

   return total_num_threads


def check_total_threads(total_num_cores,  total_num_threads):
    if total_num_threads > total_num_cores:
       print("Warning: Total number of threads ({}) is greater than total number of cores ({})".format(total_num_threads, total_num_cores))


def check_size_core_map_domain(process_d):
   for pid in process_d["pids"]:
      nrthreads = process_d["pids"][pid]["running_threads"]
      nmcores = process_d["pids"][pid]["num_core_ids"]
      if nrthreads >  nmcores:
         print("Warning: {} threads are mapped to {} core(s), for pid ({})".format(nrthreads,nmcores,pid))


def check_numa_per_process(process_d):
    for pid in process_d["pids"]:
       if  process_d["pids"][pid]["running_threads"] > 0:
           numas = process_d["pids"][pid]["numas"]
           if len(numas) > 1:
              print("Warning: pid ({} is mapped to more than one numa domain ({})".format(pid,numas))


def calc_number_processes_per_numa(number_processes_per_vm, num_numa_domains):
    if number_processes_per_vm < num_numa_domains:
       number_processes_per_numa = 1
    else:
       number_processes_per_numa = int(number_processes_per_vm / num_numa_domains)

    return number_processes_per_numa


def calc_process_pinning(number_processes_per_vm, num_numa_domains, l3cache_topo_d):
    number_processes_per_numa = calc_number_processes_per_numa(number_processes_per_vm, num_numa_domains)
    number_cores_in_l3cache = calc_number_cores_in_l3cache(l3cache_topo_d)
    indx = 0
    pinning_l = []
    while len(pinning_l) < number_processes_per_vm:
        for l3cache_id in l3cache_topo_d["l3cache_ids"]:
            if indx > len(l3cache_topo_d["l3cache_ids"][l3cache_id])-1:
               continue
            if len(pinning_l) < number_processes_per_vm:
               pinning_l.append(l3cache_topo_d["l3cache_ids"][l3cache_id][indx])
            else:
               break
        indx += 1
    return (pinning_l, number_processes_per_numa, number_cores_in_l3cache)


def calc_slurm_pinning(number_processes_per_numa, topo_2_d):
    slurm_pinning_l = []
    for numa_id in topo_2_d["numanode_ids"]:
        numa_pinning_l = []
        indx = 0
        while len(numa_pinning_l) < number_processes_per_numa:
            for l3cache_id in topo_2_d["numanode_ids"][numa_id]["l3cache_ids"]:
                if indx > len(topo_2_d["numanode_ids"][numa_id]["l3cache_ids"][l3cache_id])-1:
                   continue
                if len(numa_pinning_l) < number_processes_per_numa:
                   numa_pinning_l.append(topo_2_d["numanode_ids"][numa_id]["l3cache_ids"][l3cache_id][indx])
                else:
                   break
            indx += 1
        slurm_pinning_l += numa_pinning_l
    return (slurm_pinning_l)


def calc_slurm_pin_range(slurm_pinning_l, num_threads):
    core_id_range_l = []
    for core_id in slurm_pinning_l:
        range_end = core_id + num_threads - 1
        core_id_range = str(core_id) + "-" + str(range_end)
        core_id_range_l.append(core_id_range)
    return core_id_range_l


def execute_cmd(cmd_l):
    proc = subprocess.Popen(cmd_l, stdout=subprocess.PIPE, universal_newlines=True)
    cmd_out, errs = proc.communicate()
    return cmd_out


def convert_range_to_mask(core_id_range_l):
    slurm_mask_str = ""
    for core_id_range in core_id_range_l:
        hwloc_calc_arg = 'core:' + core_id_range
        cmd_l = ['hwloc-calc', "--taskset", hwloc_calc_arg]
        hwloc_calc_out = execute_cmd(cmd_l)
        slurm_mask_str += "," + hwloc_calc_out.rstrip()
    return slurm_mask_str[1:]


def create_gpu_numa_mask_str(topo_d, total_num_gpus):
   gpu_numa_mask_str = ""
   for gpu_id in range(0,total_num_gpus):
       for numa_id in topo_d["numanode_ids"]:
           gpu_ids_l = topo_d["numanode_ids"][numa_id]["gpu_ids"]
           if gpu_id in gpu_ids_l:
              gpu_numa_mask_str += "," + topo_d["numanode_ids"][numa_id]["mask"]
              break
   return gpu_numa_mask_str[1:]


def l3cache_id_in_numa(l3cache_l, numa_core_l):
    for core_id in l3cache_l:
        if core_id in numa_core_l:
           return True
        else:
           return False


def create_topo_2_d(topo_d, l3cache_topo_d):
    topo_2_d = {}
    topo_2_d = topo_d
    for numa_id in topo_2_d["numanode_ids"]:
        topo_2_d["numanode_ids"][numa_id]["l3cache_ids"] = {}
        for l3cache_id in l3cache_topo_d["l3cache_ids"]:
            if l3cache_id_in_numa(l3cache_topo_d["l3cache_ids"][l3cache_id], topo_d["numanode_ids"][numa_id]["core_ids"]):
               topo_2_d["numanode_ids"][numa_id]["l3cache_ids"][l3cache_id] = l3cache_topo_d["l3cache_ids"][l3cache_id]

    return topo_2_d


def check_process_numa_distribution(total_num_processes, total_num_numa_domains, process_d):
    num_numa_domains = min(total_num_processes, total_num_numa_domains)
    numas_l = []
    for pid in process_d["pids"]:
       for numa_id in process_d["pids"][pid]["numas"]:
          if numa_id not in numas_l:
             numas_l.append(numa_id)
    len_numas_l = len(numas_l)
    if len_numas_l < num_numa_domains:
       print("Warning: {} processes are mapped to {} Numa domain(s), (but {} Numa domains exist)".format(total_num_processes,len_numas_l,total_num_numa_domains))


def check_thread_to_gpu(num_threads, num_gpus):
      if num_gpus > 0:
         if num_threads < num_gpus:
            print("Warning: Virtual Machine has {} GPU's, but only {} threads are running".format(num_gpus,num_threads))
         elif num_threads > num_gpus:
            print("Warning: Virtual Machine has only {} GPU's, but {} threads are running".format(num_gpus,num_threads))


def find_l3cache_id(last_core_id, l3cache_topo_d):
    for l3cache_id in l3cache_topo_d["l3cache_ids"]:
        if int(last_core_id) in l3cache_topo_d["l3cache_ids"][l3cache_id]:
           return l3cache_id


def check_processes_to_l3cache(total_num_processes, total_num_l3caches, l3cache_topo_d, process_d):
    if l3cache_topo_d:
       num_l3caches = min(total_num_processes, total_num_l3caches)
       l3caches_l = []
       for pid in process_d["pids"]:
           last_core_id = process_d["pids"][pid]["last_core_id"]
           l3cache_id = find_l3cache_id(last_core_id,l3cache_topo_d)
           if l3cache_id not in l3caches_l:
              l3caches_l.append(l3cache_id)
       len_l3caches_l = len(l3caches_l)
       if len_l3caches_l < num_l3caches:
          print("Warning: {} processes are mapped to {} L3cache(s), (but {} L3caches exist)".format(total_num_processes,len_l3caches_l,total_num_l3caches))


def not_in_l3cache(cpus_allowed_l, l3cache_topo_d):
    l3caches_l = []
    for l3cache_id in l3cache_topo_d["l3cache_ids"]:
        for core_id in cpus_allowed_l:
            if core_id in l3cache_topo_d["l3cache_ids"][l3cache_id]:
                if l3cache_id not in l3caches_l:
                    l3caches_l.append(l3cache_id)
    if len(l3caches_l) > 1:
        cond = True
    else:
        cond = False
    return (cond,l3caches_l)


def check_threads_l3cache(total_num_processes, total_num_threads, l3cache_topo_d, process_d):
    if l3cache_topo_d:
        threads_per_process = total_num_threads / total_num_processes
        if threads_per_process > 1.0:
            for pid in process_d["pids"]:
                cpus_allowed = process_d["pids"][pid]["cpus_allowed"]
                cpus_allowed_l = range_to_list(cpus_allowed)
                (not_single_l3cache, l3caches_l) = not_in_l3cache(cpus_allowed_l, l3cache_topo_d)
                if not_single_l3cache:
                    print("Warning: threads corresponding to process {} are mapped to multiple L3cache(s) ({})".format(pid,l3caches_l))
                    break


def check_gpu_numa(total_number_gpus, process_d):
    if total_number_gpus > 0:
       for pid in process_d["pids"]:
           gpu_id = process_d["pids"][pid]["gpu_id"]
           gpus_in_numas =  process_d["pids"][pid]["gpus_in_numas"]
           if gpu_id == "None":
              print("Warning: PID ({}) is not running on any GPUs (but {} GPU's exist)".format(pid, total_number_gpus))
           if not gpu_id == "None" and not gpu_id in gpus_in_numas:
              print("Warning: PID ({}) is running on gpu_id {}, but it should be pinned to gpus {}".format(pid, gpu_id, gpus_in_numas))
           if process_d["extra_gpu_pids"]:
              print("Warning: The Following PIDS ({}) are running on the GPU's but not accounted for".format(process_d["extra_gpu_pids"]))


def check_app(app_pattern, total_num_numa_domains, total_num_gpus, topo_d, process_d, l3cache_topo_d):
   print("")
   print("")
   total_num_l3caches = calc_total_num_l3caches(l3cache_topo_d)
   total_num_cores = calc_total_num_cores(topo_d)

   if app_pattern:
      total_num_processes = calc_total_num_processes(process_d)
      total_num_threads = calc_total_num_threads(process_d)
      check_total_threads(total_num_cores,  total_num_threads)
      check_size_core_map_domain(process_d)
      check_numa_per_process(process_d)
      check_process_numa_distribution(total_num_processes, total_num_numa_domains, process_d)
      check_thread_to_gpu(total_num_threads, total_num_gpus)
      check_processes_to_l3cache(total_num_processes, total_num_l3caches, l3cache_topo_d, process_d)
      check_threads_l3cache(total_num_processes, total_num_threads, l3cache_topo_d, process_d)
      check_gpu_numa(total_num_gpus, process_d)


def calc_number_cores_in_l3cache(l3cache_topo_d):
    min_number_cores_in_l3cache = 999
    for l3cache_id in l3cache_topo_d["l3cache_ids"]:
        current_min_number_cores_in_l3cache = len(l3cache_topo_d["l3cache_ids"][l3cache_id])
        if current_min_number_cores_in_l3cache < min_number_cores_in_l3cache:
           min_number_cores_in_l3cache = current_min_number_cores_in_l3cache

    return min_number_cores_in_l3cache

      
def check_pinning_syntax(number_processes_per_vm, number_threads_per_process, topo_d, l3cache_topo_d):
   print("")
   print("")
   total_num_cores = calc_total_num_cores(topo_d)
   number_l3caches = len(l3cache_topo_d["l3cache_ids"])
   number_cores_in_l3cache = calc_number_cores_in_l3cache(l3cache_topo_d)
   num_numas = calc_total_num_numas(topo_d)
   have_warning = False

   if check_number_of_processes(number_processes_per_vm, number_threads_per_process, number_l3caches, num_numas, l3cache_topo_d):
       have_warning = True
   if check_total_number_of_threads(number_processes_per_vm, number_threads_per_process, total_num_cores):
       have_warning = True
   if check_number_threads_per_l3cache(number_processes_per_vm, number_threads_per_process, number_l3caches, number_cores_in_l3cache):
       have_warning = True
   print("")

   return have_warning


def range_to_list(range_str):
    range_str_l = range_str.split("-")
    if len(range_str_l) == 2:
        return range(int(range_str_l[0]), int(range_str_l[1])+1)
    elif len(range_str_l) == 1:
        range_str_l2 = range_str.split(",")
        if len(range_str_l2) > 2:
           return list(map(int,range_str_l2))
        else:
           return list(map(int,range_str_l))
    else:
        print("Error: function range_to_list does not support {}".format(range_str))


def ranges(i):
   for a, b in itertools.groupby(enumerate(i), lambda pair: pair[1] - pair[0]):
      b = list(b)
      yield b[0][1], b[-1][1]


def conv_ranges(range_l):
    range_str_l = []
    for item in range_l:
        if item[0] == item[1]:
           range_str = item[0]
        else:
           range_str = str(item[0]) + "-" + str(item[1])
        range_str_l.append(range_str)
    return range_str_l


def list_to_ranges(l):
    if len(l) == 1:
       return l
    else:
       range_l = list(ranges(l))
       range_str_l = conv_ranges(range_l)
       return range_str_l

def list_to_str(l):
    return ",".join(map(str,l))


def check_number_of_processes(number_processes_per_vm, number_threads_per_process, number_l3caches, num_numas, l3cache_topo_d):
    have_warning = False
    if not number_processes_per_vm % 2 == 0:
       have_warning = True
       print("Warning: You requested an odd number of MPI processes({}), it is recommended that you select an even number for better balance and distribution.".format(number_processes_per_vm))
    if number_processes_per_vm > number_l3caches and number_processes_per_vm not in l3cache_topo_d["allowed_number_of_processes"]:
       have_warning = True
       print("Warning: You requested  {} MPI processes, for this SKU its recommended you use one of these process counts, {}".format(number_processes_per_vm, l3cache_topo_d["allowed_number_of_processes"]))
    if number_threads_per_process > 1 and number_processes_per_vm > num_numas and not number_processes_per_vm % num_numas == 0:
       have_warning = True
       print("Warning: For this hybrid parallel job, the number of numa domains ({}) does not divide evenly into number of processes ({})".format(num_numas, number_processes_per_vm))
    
    return have_warning


def check_total_number_of_threads(number_processes_per_vm, number_threads_per_process, total_number_cores):
    have_warning = False
    total_number_of_threads = number_processes_per_vm * number_threads_per_process
    if total_number_of_threads > total_number_cores:
       have_warning = True
       print("Warning: You requested a total of {} threads (number of processes = {}, number of threads per process = {}), but this SKU only has {} cores".format(total_number_of_threads, number_processes_per_vm, number_threads_per_process, total_number_cores))

    return have_warning


def calc_number_processes_per_l3cache(number_processes_per_vm, number_l3caches):
    if number_processes_per_vm < number_l3caches:
       number_processes_per_l3cache = 1
    else:
       number_processes_per_l3cache = number_processes_per_vm /  number_l3caches
   
    return int(number_processes_per_l3cache)


def check_number_threads_per_l3cache(number_processes_per_vm, number_threads_per_process, number_l3caches, number_cores_in_l3cache):
    have_warning = False
    if number_threads_per_process > 1:
       number_processes_per_l3cache = calc_number_processes_per_l3cache(number_processes_per_vm, number_l3caches)
       number_threads_in_l3cache = number_processes_per_l3cache * number_threads_per_process
       if not number_threads_in_l3cache == number_cores_in_l3cache:
          have_warning = True
          print("Warning: Total number of threads in l3cache ({}) is not equal to total number of cores in l3cache ({})".format(number_threads_in_l3cache,number_cores_in_l3cache))

    return have_warning


def report(app_pattern, print_pinning_syntax, topo_d, process_d, sku_name, l3cache_topo_d, number_cores_per_vm, total_number_vms, number_processes_per_vm, number_threads_per_process, pinning_syntax_l, slurm_pinning_l, slurm_mask_str, number_processes_per_numa, number_cores_in_l3cache, mpi_type, have_warning, force, num_numas, total_num_gpus):
    hostname = socket.gethostname()
    print("")
    print("Virtual Machine ({}, {}) Numa topology".format(sku_name, hostname))
    print("")
    print("{:<12} {:<10} {:<34} {:<10}".format("NumaNode id", "Core ids", "Mask", "GPU ids"))
    print("{:=<12} {:=<10} {:=<34} {:=<10}".format("=", "=", "=", "="))
    for numnode_id in topo_d["numanode_ids"]:
       core_ids_l = str(list_to_ranges(topo_d["numanode_ids"][numnode_id]["core_ids"]))
       numa_mask = topo_d["numanode_ids"][numnode_id]["mask"]
       gpu_ids_l = str(list_to_ranges(topo_d["numanode_ids"][numnode_id]["gpu_ids"]))
       print("{:<12} {:<10} {:<34} {:<10}".format(numnode_id, core_ids_l, numa_mask, gpu_ids_l))
    print("")
    if l3cache_topo_d:
       print("{:<12} {:<20}".format("L3Cache id","Core ids"))
       print("{:=<12} {:=<20}".format("=","="))
       for l3cache_id in l3cache_topo_d["l3cache_ids"]:
          core_ids_l = str(list_to_ranges(l3cache_topo_d["l3cache_ids"][l3cache_id]))
          print("{:<12} {:<20}".format(l3cache_id,core_ids_l))
       print("")
    print("")
    if app_pattern:
       print("Application ({}) Mapping/pinning".format(app_pattern))
       print("")
       print("{:<12} {:<17} {:<17} {:<15} {:<17} {:<15} {:<15}".format("PID","Total Threads","Running Threads","Last core id","Core id mapping","Numa Node ids", "GPU ids"))
       print("{:=<12} {:=<17} {:=<17} {:=<15} {:=<17} {:=<15} {:=<15}".format("=","=","=","=","=","=","="))
       for pid in process_d["pids"]:
          threads = process_d["pids"][pid]["num_threads"]
          running_threads = process_d["pids"][pid]["running_threads"]
          last_core_id = process_d["pids"][pid]["last_core_id"]
          cpus_allowed = process_d["pids"][pid]["cpus_allowed"]
          numas = str(list_to_ranges(process_d["pids"][pid]["numas"]))
          gpu_id = process_d["pids"][pid]["gpu_id"]
          print("{:<12} {:<17} {:<17} {:<15} {:<17} {:<15} {:<15}".format(pid,threads,running_threads,last_core_id,cpus_allowed,numas,gpu_id))
    elif print_pinning_syntax:
       total_number_processes = total_number_vms * number_processes_per_vm
       f = open("AZ_MPI_NP", "w")
       f.write(str(total_number_processes))
       f.close
       print("Process/thread {} MPI mapping/pinning syntax for total {} processes ( {} processes per VM and {} threads per process)".format(mpi_type, total_number_processes, number_processes_per_vm, number_threads_per_process))
       print("")
       if sku_name == "Standard_HB120rs_v3" and number_threads_per_process > 1:
          print("Warning: You are planning on running a hybrid parallel application on {}, it is recommended that you use Standard_HB120-96rs_v3, Standard_HB120-64rs_v3 or Standard_HB120-32rs_v3 instead.".format(sku_name))
          sys.exit(1)
       if sku_name == "Standard_HB120rs_v2" and number_threads_per_process > 1:
          print("Warning: You are planning on running a hybrid parallel application on {}, it is recommended that you use Standard_HB120-96rs_v2, Standard_HB120-64rs_v2 or Standard_HB120-32rs_v2 instead.".format(sku_name))
          sys.exit(1)
       if have_warning and not force:
          print("NOTE: MPI process/thread pinning syntax will NOT be displayed until the warnings above have been corrected")
       else:
          f = open("AZ_MPI_ARGS", "w")
          if mpi_type == "openmpi":
             if number_threads_per_process == 1 and number_processes_per_vm == number_cores_per_vm:
                az_mpi_args = "--bind-to cpulist:ordered --cpu-list {} -report-bindings".format(list_to_str(pinning_syntax_l))
                print("mpirun -np {} {}".format(total_number_processes, az_mpi_args))
             else:
                az_mpi_args = "--bind-to l3cache --map-by ppr:{}:numa -report-bindings".format(number_processes_per_numa)
                print("mpirun -np {} {}".format(total_number_processes, az_mpi_args))
          elif mpi_type == "srun":
             if total_num_gpus == 0 or total_num_gpus != number_processes_per_vm:
                az_mpi_args = "--mpi=pmix --cpu-bind=mask_cpu:{} --ntasks-per-node={}".format(slurm_mask_str, number_processes_per_vm)
                print("core id pinning: {}\n".format(slurm_pinning_l))
                print("srun {}".format(az_mpi_args))
             else:
                gpu_numa_mask_str = create_gpu_numa_mask_str(topo_d, total_num_gpus)
                az_mpi_args = "--mpi=pmix --cpu-bind=mask_cpu:{} --ntasks-per-node={} --gpus-per-node={}".format(gpu_numa_mask_str, number_processes_per_vm, total_num_gpus)
                print("srun {}".format(az_mpi_args))
          elif mpi_type == "bsub":
             if number_threads_per_process == 1:
                az_mpi_args = "-R \"span[ptile={}] affinity[core(1):membind=localonly:distribute=balance]\"".format(number_processes_per_vm)
                print("bsub {}".format(az_mpi_args))
             else:
                az_mpi_args = "-R \"span[ptile={}] affinity[core({}, same=numa):membind=localonly:distribute=balance]\"".format(number_processes_per_vm, number_cores_in_l3cache)
                print("bsub {}".format(az_mpi_args))
          elif mpi_type == "intel":
             num_l3cache = len(l3cache_topo_d["l3cache_ids"])
             if number_threads_per_process == 1:
                az_mpi_args = "-genv I_MPI_PIN_PROCESSOR {} -genv FI_PROVIDER mlx -genv I_MPI_COLL_EXTERNAL 1 -genv I_MPI_DEBUG 6".format(list_to_str(pinning_syntax_l))
                print("mpirun -np {} {}".format(total_number_processes, az_mpi_args))
             elif number_processes_per_vm < num_l3cache:
                az_mpi_args = "-genv I_MPI_PIN_DOMAIN {} -genv FI_PROVIDER mlx -genv I_MPI_COLL_EXTERNAL 1 -genv I_MPI_DEBUG 6".format("auto:compact")
                print("mpirun -np {} {}".format(total_number_processes, az_mpi_args))
             else:
                az_mpi_args = "-genv I_MPI_PIN_DOMAIN {}:compact -genv FI_PROVIDER mlx -genv I_MPI_COLL_EXTERNAL 1 -genv I_MPI_DEBUG 6".format(number_cores_in_l3cache)
                print("mpirun -np {} {}".format(total_number_processes, az_mpi_args))
          else:
             if number_threads_per_process == 1:
                az_mpi_args = "-genv MV2_SHOW_CPU_BINDING=1 -genv MV2_CPU_BINDING_POLICY=scatter -genv MV2_CPU_BINDING_LEVEL=core"
                print("mpirun -np {} {}".format(total_number_processes, az_mpi_args))
             else:
                az_mpi_args = "-genv MV2_SHOW_CPU_BINDING=1 -genv MV2_THREADS_PER_PROCESS={} -genv MV2_CPU_BINDING_POLICY=hybrid -genv MV2_HYBRID_BINDING_POLICY=linear".format(number_cores_in_l3cache)
                print("mpirun -np {} {}".format(total_number_processes, az_mpi_args))
          f.write(az_mpi_args)
          f.close

def main():
   total_number_vms = 0
   number_processes_per_vm = 0
   number_threads_per_process = 0
   pinning_l = []
   slurm_pinning_l = []
   slurm_mask_str = ""
   process_d = {}
   number_processes_per_numa = 0
   number_cores_in_l3cache = 0
   mpi_type = "None"
   have_warning = False
   vm_metadata = get_vm_metadata()
   sku_name = vm_metadata["compute"]["vmSize"]
   parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
   parser.add_argument("-anp", "--application_name_pattern", dest="application_pattern", type=str, help="Select the application pattern to check [string]")
   parser.add_argument("-pps", "--print_pinning_syntax", action="store_true", help="Print MPI pinning syntax")
   parser.add_argument("-f", "--force", action="store_true", help="Force printing MPI pinning syntax (i.e ignore warnings)")
   parser.add_argument("-nv", "--total_number_vms", dest="total_number_vms", type=int, default=1, help="Total number of VM's (used with -pps)")
   parser.add_argument("-nppv", "--number_processes_per_vm", dest="number_processes_per_vm", type=int, help="Total number of MPI processes per VM (used with -pps)")
   parser.add_argument("-ntpp", "--number_threads_per_process", dest="number_threads_per_process", type=int, help="Number of threads per process (used with -pps)")
   parser.add_argument("-mt", "--mpi_type", dest="mpi_type", type=str, choices=["openmpi","intel","mvapich2","srun","bsub"], default="openmpi", help="Select which type of MPI to generate pinning syntax (used with -pps)(select srun when you are using a SLURM scheduler adn bsub with using an LSF scheduler)")
   args = parser.parse_args()
   force = args.force
   if len(sys.argv) > 1 and not args.application_pattern and not args.print_pinning_syntax:
      print("Error: you must select either an application_name_pattern(-anp) (to see where your application is pinned)  or print_pinning_syntax (-pps) (to see the MPI pinning syntax), -h argument will show you all argument options.")
      sys.exit(1)
   topo_d = parse_lstopo()
   total_num_numa_domains = calc_total_num_numas(topo_d)
   total_num_gpus = calc_total_num_gpus(topo_d)
   l3cache_topo_d = create_l3cache_topo(sku_name)
   number_cores_per_vm = calc_total_num_cores(topo_d)
   if args.application_pattern:
      app_pattern = args.application_pattern
      pids_l = find_pids(app_pattern)
      process_d = find_threads(pids_l)
      find_process_numas(topo_d, process_d)
      find_process_gpus(topo_d, process_d)
      find_last_core_id(process_d)
      parse_nvidia_smi(total_num_gpus, process_d)
   if args.print_pinning_syntax:
      (sku_found, supported_sku_names_l) = check_if_sku_is_supported(sku_name)
      if not sku_found:
          print("Error: {} is currently not a supported SKU to determine the correct process/thread MPI pinning/mapping syntax.\n The following SKUs are supported {}".format(sku_name, supported_sku_names_l))
          sys.exit(1)
      process_d = {}
      if args.total_number_vms:
         total_number_vms = args.total_number_vms
      else:
         total_number_vms = 1
      if args.number_processes_per_vm:
         number_processes_per_vm = args.number_processes_per_vm
      else:
         number_processes_per_vm = number_cores_per_vm
      if args.number_threads_per_process:
         number_threads_per_process = args.number_threads_per_process
      else:
         number_threads_per_process = 1
      if args.mpi_type:
          mpi_type = args.mpi_type
      else:
          mpi_type = "openmpi"
      have_warning = check_pinning_syntax(number_processes_per_vm, number_threads_per_process, topo_d, l3cache_topo_d)
      (pinning_l, number_processes_per_numa, number_cores_in_l3cache) = calc_process_pinning(number_processes_per_vm, total_num_numa_domains, l3cache_topo_d)

   if mpi_type == "srun":
      if total_num_gpus == 0 or total_num_gpus != number_processes_per_vm:
         topo_2_d = create_topo_2_d(topo_d, l3cache_topo_d)
         slurm_pinning_l = calc_slurm_pinning(number_processes_per_numa, topo_2_d)
         slurm_pinning_l = calc_slurm_pin_range(slurm_pinning_l, number_threads_per_process)
         slurm_mask_str = convert_range_to_mask(slurm_pinning_l)

   report(args.application_pattern, args.print_pinning_syntax, topo_d, process_d, sku_name, l3cache_topo_d, number_cores_per_vm, total_number_vms, number_processes_per_vm, number_threads_per_process, pinning_l, slurm_pinning_l, slurm_mask_str, number_processes_per_numa, number_cores_in_l3cache, mpi_type, have_warning, force, total_num_numa_domains, total_num_gpus)
   check_app(args.application_pattern,  total_num_numa_domains, total_num_gpus, topo_d, process_d, l3cache_topo_d)


if __name__ == "__main__":
    main()

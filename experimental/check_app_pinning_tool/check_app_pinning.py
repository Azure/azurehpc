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

l3cache_coreid_d = {"Standard_HB120rs_v3": ["0-7","8-15","16-23","24-29","30-37","38-45","46-53","54-59","60-67","68-75","76-83","84-89","90-97","98-105","106-113","114-119"]}
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
                                                          }},
                    "Standard_HB120-96rs_v3": {"l3cache_ids":  {0: [0,1,2,3,4,5],\
                                                                1: [6,7,8,9,10,11],\
                                                                2: [12,13,14,15,16,17],\
                                                                3: [18,19,20,21,22,23],\
                                                                4: [24,25,26,27,28,29],\
                                                                5: [30,31,32,33,34,35],\
                                                                6: [36,37,38,39,40,41],\
                                                                7: [42,43,44,45,46,47],\
                                                                8: [48,48,50,51,52,53],\
                                                                9: [54,55,56,57,58,59],\
                                                               10: [60,61,62,63,64,65],\
                                                               11: [66,67,68,69,70,71],\
                                                               12: [72,73,74,75,76,77],\
                                                               13: [78,79,80,81,82,83],\
                                                               14: [84,85,86,87,88,89],\
                                                               15: [90,91,92,93,94,95]\
                                                          }},
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
                                                          }},
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
                                                          }},
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
                                                          }},
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
                                                          }}}


def get_vm_metadata():
    metadata_url = "http://169.254.169.254/metadata/instance?api-version=2017-08-01"
    metadata_req = Request(metadata_url, headers={"Metadata": True})

    for _ in range(30):
#        print("Fetching metadata")
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
   cmd = ["lstopo-no-graphics", "--no-caches"]
   try:
      cmdpipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
   except FileNotFoundError:
      print("Error: Could not find the executable (lstopo-on-graphics), make sure you have installed the hwloc package.")
      sys.exit(1)
#print(cmdpipe.stderr.readline())
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
#          print(numanode)
          topo_d["numanode_ids"][numanode] = {}
          topo_d["numanode_ids"][numanode]["core_ids"] = []
          topo_d["numanode_ids"][numanode]["gpu_ids"] = []
       if "Core" in row_s:
          row_l = row_s.split()
          core_id = re.findall(r'\d+',row_l[-1])[0]
          topo_d["numanode_ids"][numanode]["core_ids"].append(int(core_id))
       if re.search(r'GPU.*card', row_s):
          row_l = row_s.split()
          gpu_id = re.findall(r'\d+',row_l[-1])[0]
          topo_d["numanode_ids"][numanode]["gpu_ids"].append(int(gpu_id))
   cmdpipe.stdout.close()
   cmdpipe.stderr.close()
#   print(topo_d)
   return topo_d


def create_l3cache_topo(actual_sku_name):
    l3cache_topo_d = {}
    for sku_name in l3cache_coreid_d:
        if sku_name == actual_sku_name:
           l3cache_topo_d = l3cache_coreid_d[sku_name]
           break

    return l3cache_topo_d


def find_pids(pattern):
   cmd = ["pgrep",pattern]
   pids_l = []
   cmdpipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
   bpids_l = cmdpipe.stdout.readlines()
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
#       print("Num running threads = ",nrthreads)
       filepath = os.path.join("/proc",str(pid),"status")
       f = open(filepath)
       for line in f:
           if "Threads" in line:
              num_threads = line.split(":")[1].strip()
              process_d["pids"][pid]["num_threads"] = num_threads
              process_d["pids"][pid]["running_threads"] = nrthreads
#              print(num_threads)
           if "Cpus_allowed_list" in line:
              cpus_allowed = line.split(":")[1].strip()
              process_d["pids"][pid]["cpus_allowed"] = cpus_allowed
#              print(cpus_allowed)
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
      process_d["pids"][pid]["gpus"] = all_gpus_l


def find_last_core_id(process_d): 
   for pid in process_d["pids"]:
       filepath = os.path.join("/proc",str(pid),"stat")
       f = open(filepath)
       for line in f:
           last_core_id = line.split()[38]
       process_d["pids"][pid]["last_core_id"] = last_core_id
   

def conv_indx_str_to_list(indx_str):
    indx_l = []
    if "-" in indx_str:
       indx_str_l = indx_str.split("-")
       return list(range(int(indx_str_l[0]),int(indx_str_l[1])+1))
    elif "," in indx_str:
       return list(map(int, indx_str.split(",")))
    else:
       indx_l.append(int(indx_str))
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


def check_process_numa_distribution(total_num_processes, total_num_numa_domains, process_d):
    num_numa_domains = min(total_num_processes, total_num_numa_domains)
    numas_l = []
    for pid in process_d["pids"]:
#       numas = process_d["pids"][pid]["numas"]
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


def check_app(topo_d, process_d, l3cache_topo_d):
   print("")
   print("")
   total_num_processes = calc_total_num_processes(process_d)
   total_num_numa_domains = calc_total_num_numas(topo_d)
   total_num_l3caches = calc_total_num_l3caches(l3cache_topo_d)
   total_num_cores = calc_total_num_cores(topo_d)
   total_num_threads = calc_total_num_threads(process_d)
   total_num_gpus = calc_total_num_gpus(topo_d)

   check_total_threads(total_num_cores,  total_num_threads)
   check_size_core_map_domain(process_d)
   check_numa_per_process(process_d)
   check_process_numa_distribution(total_num_processes, total_num_numa_domains, process_d)
   check_thread_to_gpu(total_num_threads, total_num_gpus)
   check_processes_to_l3cache(total_num_processes, total_num_l3caches, l3cache_topo_d, process_d)
   check_threads_l3cache(total_num_processes, total_num_threads, l3cache_topo_d, process_d)


def range_to_list(range_str):
    range_str_l = range_str.split("-")
    if len(range_str_l) == 2:
        return range(int(range_str_l[0]), int(range_str_l[1])+1)
    elif len(range_str_l) == 1:
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


def report(app_pattern, topo_d, process_d, sku_name, l3cache_topo_d):
    hostname = socket.gethostname()
    print("")
    print("Virtual Machine ({}) Numa topology".format(sku_name))
    print("")
    print("{:<12} {:<20}  {:<10}".format("NumaNode id","Core ids", "GPU ids"))
    print("{:=<12} {:=<20} {:=<10}".format("=","=", "="))
    for numnode_id in topo_d["numanode_ids"]:
       core_ids_l = str(list_to_ranges(topo_d["numanode_ids"][numnode_id]["core_ids"]))
       gpu_ids_l = str(list_to_ranges(topo_d["numanode_ids"][numnode_id]["gpu_ids"]))
       print("{:<12} {:<20} {:<10}".format(numnode_id,core_ids_l, gpu_ids_l))
    print("")
    if l3cache_topo_d:
       print("{:<12} {:<20}".format("L3Cache id","Core ids"))
       print("{:=<12} {:=<20}".format("=","="))
       for l3cache_id in l3cache_topo_d["l3cache_ids"]:
          core_ids_l = str(list_to_ranges(l3cache_topo_d["l3cache_ids"][l3cache_id]))
          print("{:<12} {:<20}".format(l3cache_id,core_ids_l))
       print("")
    print("")
    print("Application ({}) Mapping/pinning".format(app_pattern))
    print("")
    print("{:<12} {:<17} {:<17} {:<15} {:<17} {:<15} {:<15}".format("PID","Threads","Running Threads","Last core id","Core id mapping","Numa Node ids", "GPU ids"))
    print("{:=<12} {:=<17} {:=<17} {:=<15} {:=<17} {:=<15} {:=<15}".format("=","=","=","=","=","=","="))
    for pid in process_d["pids"]:
       threads = process_d["pids"][pid]["num_threads"]
       running_threads = process_d["pids"][pid]["running_threads"]
       last_core_id = process_d["pids"][pid]["last_core_id"]
       cpus_allowed = process_d["pids"][pid]["cpus_allowed"]
       numas = str(list_to_ranges(process_d["pids"][pid]["numas"]))
       gpus = str(list_to_ranges(process_d["pids"][pid]["gpus"]))
       print("{:<12} {:<17} {:<17} {:<15} {:<17} {:<15} {:<15}".format(pid,threads,running_threads,last_core_id,cpus_allowed,numas,gpus))


def main():
   vm_metadata = get_vm_metadata()
   sku_name = vm_metadata["compute"]["vmSize"]
   parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
   parser.add_argument(dest="application_pattern", type=str, default="None", help="Select the application pattern to check [string]")
   args = parser.parse_args()
   if args.application_pattern:
      app_pattern = args.application_pattern
   topo_d = parse_lstopo()
   l3cache_topo_d = create_l3cache_topo(sku_name)
#   print(l3cache_topo_d)
   pids_l = find_pids(app_pattern)
   process_d = find_threads(pids_l)
   find_process_numas(topo_d, process_d)
   find_process_gpus(topo_d, process_d)
   find_last_core_id(process_d)
   report(app_pattern, topo_d, process_d, sku_name, l3cache_topo_d)
   check_app(topo_d, process_d, l3cache_topo_d)


if __name__ == "__main__":
    main()

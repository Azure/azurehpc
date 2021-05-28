#!/usr/bin/python3

import subprocess
import sys
import os
import re
import argparse
import itertools
import socket


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


def check_app(topo_d, process_d):
   print("")
   print("")
   total_num_processes = calc_total_num_processes(process_d)
   total_num_numa_domains = calc_total_num_numas(topo_d)
   total_num_cores = calc_total_num_cores(topo_d)
   total_num_threads = calc_total_num_threads(process_d)
   total_num_gpus = calc_total_num_gpus(topo_d)

   check_total_threads(total_num_cores,  total_num_threads)
   check_size_core_map_domain(process_d)
   check_numa_per_process(process_d)
   check_process_numa_distribution(total_num_processes, total_num_numa_domains, process_d)
   check_thread_to_gpu(total_num_threads, total_num_gpus)


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


def report(app_pattern, topo_d, process_d):
    hostname = socket.gethostname()
    print("")
    print("Virtual Machine ({}) Numa topology".format(hostname))
    print("")
    print("{:<12} {:<20}  {:<10}".format("NumaNode id","Core ids", "GPU ids"))
    print("{:=<12} {:=<20} {:=<10}".format("=","=", "="))
    for numnode_id in topo_d["numanode_ids"]:
       core_ids_l = str(list_to_ranges(topo_d["numanode_ids"][numnode_id]["core_ids"]))
       gpu_ids_l = str(list_to_ranges(topo_d["numanode_ids"][numnode_id]["gpu_ids"]))
       print("{:<12} {:<20} {:<10}".format(numnode_id,core_ids_l, gpu_ids_l))
    print("")
    print("")
    print("Application ({}) Mapping/pinning".format(app_pattern))
    print("")
    print("{:<12} {:<17} {:<17} {:<17} {:<15} {:<15}".format("PID","Threads","Running Threads","Core id mapping","Numa Node ids", "GPU ids"))
    print("{:=<12} {:=<17} {:=<17} {:=<17} {:=<15} {:=<15}".format("=","=","=","=","=","="))
    for pid in process_d["pids"]:
       threads = process_d["pids"][pid]["num_threads"]
       running_threads = process_d["pids"][pid]["running_threads"]
       cpus_allowed = process_d["pids"][pid]["cpus_allowed"]
       numas = str(list_to_ranges(process_d["pids"][pid]["numas"]))
       gpus = str(list_to_ranges(process_d["pids"][pid]["gpus"]))
       print("{:<12} {:<17} {:<17} {:<17} {:<15} {:<15}".format(pid,threads,running_threads,cpus_allowed,numas,gpus))


def main():
   parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
   parser.add_argument(dest="application_pattern", type=str, default="None", help="Select the application pattern to check [string]")
   args = parser.parse_args()
   if args.application_pattern:
      app_pattern = args.application_pattern
   topo_d = parse_lstopo()
   pids_l = find_pids(app_pattern)
   process_d = find_threads(pids_l)
   find_process_numas(topo_d, process_d)
   find_process_gpus(topo_d, process_d)
   report(app_pattern, topo_d, process_d)
   check_app(topo_d, process_d)


if __name__ == "__main__":
    main()

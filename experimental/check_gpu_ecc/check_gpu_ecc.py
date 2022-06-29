#!/usr/bin/python3

import subprocess
import sys
import os
import re
import argparse
import itertools
import socket
import json
import csv
from urllib.request import urlopen, Request


ECC_COUNTER_THRESHOLD = 10000000
supported_skus_list = ["Standard_ND96asr_v4", "Standard_ND96amsr_A100_v4"]


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


def parse_nvidia_smi_remapped_rows(ecc_d):
    GPU_REMAPPED_ROWS_QUERY = "gpu_uuid,remapped_rows.pending,remapped_rows.failure,remapped_rows.correctable,remapped_rows.uncorrectable"
    ecc_d["gpu_uuid"] = {}
    cmd = ["nvidia-smi", "--query-remapped-rows={}".format(GPU_REMAPPED_ROWS_QUERY), "--format=csv,noheader"]
    try:
       cmdpipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8")
    except FileNotFoundError:
       print("Error: Could not find the executable (nvidia-smi), make sure you have installed the Nvidia GPU driver.")
       sys.exit(1)
    gpu_remapped_rows_l = csv.reader(cmdpipe.stdout.readlines())
    for gpu_remapped_rows in gpu_remapped_rows_l:
        ecc_d["gpu_uuid"][gpu_remapped_rows[0]] = {}
        ecc_d["gpu_uuid"][gpu_remapped_rows[0]]["RRP"] = int(gpu_remapped_rows[1])
        ecc_d["gpu_uuid"][gpu_remapped_rows[0]]["RRE"] = int(gpu_remapped_rows[2])
        ecc_d["gpu_uuid"][gpu_remapped_rows[0]]["RRC"] = int(gpu_remapped_rows[3])
        ecc_d["gpu_uuid"][gpu_remapped_rows[0]]["RRU"] = int(gpu_remapped_rows[4])

    return ecc_d


def parse_nvidia_smi_gpu(ecc_d):
    GPU_QUERY = "gpu_uuid,ecc.errors.uncorrected.volatile.sram,ecc.errors.uncorrected.aggregate.sram,ecc.errors.corrected.volatile.sram,ecc.errors.corrected.aggregate.sram,ecc.errors.uncorrected.volatile.dram,ecc.errors.uncorrected.aggregate.dram,ecc.errors.corrected.volatile.dram,ecc.errors.corrected.aggregate.dram"
    cmd = ["nvidia-smi", "--query-gpu={}".format(GPU_QUERY), "--format=csv,noheader"]
    try:
       cmdpipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8")
    except FileNotFoundError:
       print("Error: Could not find the executable (nvidia-smi), make sure you have installed the Nvidia GPU driver.")
       sys.exit(1)
    gpu_l = csv.reader(cmdpipe.stdout.readlines())
    for gpu in gpu_l:
        ecc_d["gpu_uuid"][gpu[0]]["EEUVS"] = int(gpu[1])
        ecc_d["gpu_uuid"][gpu[0]]["EEUAS"] = int(gpu[2])
        ecc_d["gpu_uuid"][gpu[0]]["EECVS"] = int(gpu[3])
        ecc_d["gpu_uuid"][gpu[0]]["EECAS"] = int(gpu[4])
        ecc_d["gpu_uuid"][gpu[0]]["EEUVD"] = int(gpu[5])
        ecc_d["gpu_uuid"][gpu[0]]["EEUAD"] = int(gpu[6])
        ecc_d["gpu_uuid"][gpu[0]]["EECVD"] = int(gpu[7])
        ecc_d["gpu_uuid"][gpu[0]]["EECAD"] = int(gpu[8])

    return ecc_d


def parse_nvidia_smi_gpu_id(ecc_d):
    cmd = ["nvidia-smi", "-L"]
    try:
       cmdpipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8")
    except FileNotFoundError:
       print("Error: Could not find the executable (nvidia-smi), make sure you have installed the Nvidia GPU driver.")
       sys.exit(1)
    gpu_id_l = cmdpipe.stdout.readlines()
    for gpu_id_str in gpu_id_l:
        gpu_id_str_split = gpu_id_str.split()
        gpu_id = gpu_id_str_split[1][:-1]
        gpu_uuid = gpu_id_str_split[5][:-1]
        ecc_d["gpu_uuid"][gpu_uuid]["gpu_id"] = gpu_id

    return ecc_d


def check_gpu_remapped_rows_pending(ecc_d, hostname):
    for gpu_uuid in ecc_d["gpu_uuid"]:
        if ecc_d["gpu_uuid"][gpu_uuid]["RRP"] > 0:
           gpu_id = ecc_d["gpu_uuid"][gpu_uuid]["gpu_id"]
           print("Warning: Detected a GPU pending row remap for GPU ID {}, please re-boot this node ({}) to clear this pending row remap.".format(gpu_id,hostname))


def check_gpu_remapped_rows_error(ecc_d, hostname):
    for gpu_uuid in ecc_d["gpu_uuid"]:
        if ecc_d["gpu_uuid"][gpu_uuid]["RRE"] > 0:
           gpu_id = ecc_d["gpu_uuid"][gpu_uuid]["gpu_id"]
           print("Warning: Detected a GPU row remap Error for GPU ID {}, please offline this node ({}), get the HPC diagnostics and submit a support request.".format(gpu_id,hostname))


def check_gpu_remapped_rows_uncorrectable(ecc_d, hostname):
    for gpu_uuid in ecc_d["gpu_uuid"]:
        rru = ecc_d["gpu_uuid"][gpu_uuid]["RRU"]
        if rru > 512:
           gpu_id = ecc_d["gpu_uuid"][gpu_uuid]["gpu_id"]
           print("Warning: Detected {} GPU row remap uncorrectable Errors for GPU ID {}, please offline this node ({}), get the HPC diagnostics and submit a support request.".format(rru,gpu_id,hostname))


def check_gpu_sram(ecc_d, hostname):
    for gpu_uuid in ecc_d["gpu_uuid"]:
        gpu_id = ecc_d["gpu_uuid"][gpu_uuid]["gpu_id"]
        if ecc_d["gpu_uuid"][gpu_uuid]["EEUVS"] > 0:
           print("Warning: Detected a GPU SRAM uncorrectable error for the volatile counter for GPU ID {}, please offline this node ({}), get the HPC diagnostics and submit a support request.".format(gpu_id,hostname))
        if ecc_d["gpu_uuid"][gpu_uuid]["EEUAS"] > 0:
           print("Warning: Detected a GPU SRAM uncorrectable error for the aggregate counter for GPU ID {}, please offline this node ({}), get the HPC diagnostics and submit a support request.".format(gpu_id,hostname))
        if ecc_d["gpu_uuid"][gpu_uuid]["EECVS"] > 0:
           print("Warning: Detected a GPU SRAM correctable error for the volatile counter for GPU ID {}, please offline this node ({}), get the HPC diagnostics and submit a support request.".format(gpu_id,hostname))
        if ecc_d["gpu_uuid"][gpu_uuid]["EECAS"] > 0:
           print("Warning: Detected a GPU SRAM correctable error for the aggregate counter for GPU ID {}, please offline this node ({}), get the HPC diagnostics and submit a support request.".format(gpu_id,hostname))


def check_gpu_high_ecc_counter(ecc_d, hostname):
    for gpu_uuid in ecc_d["gpu_uuid"]:
        gpu_id = ecc_d["gpu_uuid"][gpu_uuid]["gpu_id"]
        if ecc_d["gpu_uuid"][gpu_uuid]["EEUVD"] > ECC_COUNTER_THRESHOLD:
           ecc_counter = ecc_d["gpu_uuid"][gpu_uuid]["EEUVD"]
           print("Warning: Detected a very high GPU DRAM uncorrectable error count ({}) for the volatile counter for GPU ID {}, please try a reboot, if the counter increases again and you experience instability or performance degradation, then offline this node ({}), get the HPC diagnostics and submit a support request.".format(ecc_counter,gpu_id,hostname))
        if ecc_d["gpu_uuid"][gpu_uuid]["EEUAD"] > ECC_COUNTER_THRESHOLD:
           ecc_counter = ecc_d["gpu_uuid"][gpu_uuid]["EEUAD"]
           print("Warning: Detected a very high GPU DRAM uncorrectable error count ({}) for the aggregate counter for GPU ID {}, please try a reboot, if the volatile counter increases again and you experience instability or performance degradation, then offline this node ({}), get the HPC diagnostics and submit a support request.".format(ecc_counter,gpu_id,hostname))
        if ecc_d["gpu_uuid"][gpu_uuid]["EECVD"] > ECC_COUNTER_THRESHOLD:
           ecc_counter = ecc_d["gpu_uuid"][gpu_uuid]["EECVD"]
           print("Warning: Detected a very high GPU DRAM correctable error count ({}) for the volatile counter for GPU ID {}, please try a reboot, if the counter increases again and you experience instability or performance degradation, then offline this node ({}), get the HPC diagnostics and submit a support request.".format(ecc_counter,gpu_id,hostname))
        if ecc_d["gpu_uuid"][gpu_uuid]["EECAD"] > ECC_COUNTER_THRESHOLD:
           ecc_counter = ecc_d["gpu_uuid"][gpu_uuid]["EECAD"]
           print("Warning: Detected a very high GPU DRAM correctable error count ({}) for the aggregate counter for GPU ID {}, please try a reboot, if the volatile counter increases again and you experience instability or performance degradation, then offline this node ({}), get the HPC diagnostics and submit a support request.".format(ecc_counter,gpu_id,hostname))


def check_if_sku_is_supported(actual_sku_name):
    sku_found = False
    for sku_name in supported_skus_list:
        if sku_name == actual_sku_name:
           sku_found = True
           break
    
    return sku_found


def report(ecc_d, sku_name, hostname):

    print("")
    print("GPU ECC error report for ({}, {})".format(sku_name, hostname))
    print("")
    print("{:<8} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10}".format("GPU id","RRP", "RRE", "RRC", "RRU", "EEUVS", "EEUAS", "EECVS", "EECAS", "EEUVD", "EEUAD", "EECVD", "EECAD"))
    print("{:=<8} {:=<10} {:=<10} {:=<10} {:=<10} {:=<10} {:=<10} {:=<10} {:=<10} {:=<10} {:=<10} {:=<10} {:=<10}".format("=","=","=","=","=","=","=","=","=","=","=","=","="))
    for gpu_uuid in ecc_d["gpu_uuid"]:
       gpu_id = ecc_d["gpu_uuid"][gpu_uuid]["gpu_id"]
       rrp = ecc_d["gpu_uuid"][gpu_uuid]["RRP"]
       rre = ecc_d["gpu_uuid"][gpu_uuid]["RRE"]
       rrc = ecc_d["gpu_uuid"][gpu_uuid]["RRC"]
       rru = ecc_d["gpu_uuid"][gpu_uuid]["RRU"]
       eeuvs = ecc_d["gpu_uuid"][gpu_uuid]["EEUVS"]
       eeuas = ecc_d["gpu_uuid"][gpu_uuid]["EEUAS"]
       eecvs = ecc_d["gpu_uuid"][gpu_uuid]["EECVS"]
       eecas = ecc_d["gpu_uuid"][gpu_uuid]["EECAS"]
       eeuvd = ecc_d["gpu_uuid"][gpu_uuid]["EEUVD"]
       eeuad = ecc_d["gpu_uuid"][gpu_uuid]["EEUAD"]
       eecvd = ecc_d["gpu_uuid"][gpu_uuid]["EECVD"]
       eecad = ecc_d["gpu_uuid"][gpu_uuid]["EECAD"]
       print("{:<8} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10} {:<10}".format(gpu_id,rrp,rre,rrc,rru,eeuvs,eeuas,eecvs,eecas,eeuvd,eeuad,eecvd,eecad))
    print("")
    print("Legend")
    print("{:=<10}".format("="))
    print("RRP: Row remap pending")
    print("RRE: Row remap error")
    print("RRC: Row remap correctable error count")
    print("RRU: Row remap uncorrectable error count")
    print("EEUVS: ECC Errors uncorrectable volatile SRAM count")
    print("EEUAS: ECC Errors uncorrectable aggregate SRAM count")
    print("EECVS: ECC Errors correctable volatile SRAM count")
    print("EECAS: ECC Errors correctable aggregate SRAM count")
    print("EEUVD: ECC Errors uncorrectable volatile DRAM count")
    print("EECAD: ECC Errors uncorrectable aggregate DRAM count")
    print("EECVD: ECC Errors correctable volatile DRAM count")
    print("EECAD: ECC Errors correctable aggregate DRAM count")
    print("")


def main():
   ecc_d = {}
   vm_metadata = get_vm_metadata()
   sku_name = vm_metadata["compute"]["vmSize"]
   hostname = socket.gethostname()
   sku_found = check_if_sku_is_supported(sku_name)
   if not sku_found:
      print("Error: {} is currently not a supported SKU.\n The following SKUs are supported {}".format(sku_name, supported_skus_list))
      sys.exit(1)
   ecc_d = parse_nvidia_smi_remapped_rows(ecc_d)
   ecc_d = parse_nvidia_smi_gpu(ecc_d)
   ecc_d = parse_nvidia_smi_gpu_id(ecc_d)
   report(ecc_d, sku_name, hostname)
   check_gpu_remapped_rows_pending(ecc_d, hostname)
   check_gpu_remapped_rows_error(ecc_d, hostname)
   check_gpu_remapped_rows_uncorrectable(ecc_d, hostname)
   check_gpu_sram(ecc_d, hostname)
   check_gpu_high_ecc_counter(ecc_d, hostname)


if __name__ == "__main__":
    main()

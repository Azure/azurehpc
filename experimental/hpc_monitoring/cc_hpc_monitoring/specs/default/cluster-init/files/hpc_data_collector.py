#!/usr/bin/python3 -u

import json
import requests
import datetime
import hashlib
import hmac
import base64
import subprocess
import socket
import os
import sys
import glob
import struct
import time
import argparse


# Some useful DCGM field ID's (for GPU monitoring)
#110: sm_app_clock (expect 1410 on A100, assume MHz)
#110: mem_app_clock (expect 1215 on A100, assume MHz))
#150: gpu_temp (in C)
#203: gpu_utilization
#252: fb_used  (GPU memory used)
#1004: Tensor_active
#1006: fp64_active
#1007: fp32_active
#1008: fp16_active

# Update the customer ID to your Log Analytics workspace ID
# You can also use LOG_ANALYTICS_CUSTOMER_ID environmental variable, if you set this variable here the environmental variable 
# will be ignored.
#customer_id = 'XXXXXXXXXXX'

# For the shared key, use either the primary or the secondary Connected Sources client authentication key.
# You can also use LOG_ANALYTICS_SHARED_KEY environmental variable, if you set this variable here the environmental variable
# will be ignored.
#shared_key = 'XXXXXXXXXXXXX'

#NUMBER_IB_LINKS = 4
IB_COUNTERS = [
                'port_xmit_data',
                'port_rcv_data'
              ]
# If need to monitor InfiniBand errors, add these counters
#    'port_xmit_discards',
#    'port_rcv_errors',
#    'port_xmit_constraint_errors',
#    'port_rcv_constraint_errors',

ETH_COUNTERS = [
                'tx_bytes',
                'rx_bytes'
              ]
# If need to monitor Ethernet errors, add these counters
#    'tx_dropped',
#    'tx_errors',
#    'rx_errors',
#    'rx_dropped',

CPU_MEM_COUNTERS = [
                'MemTotal',
                'MemFree'
              ]
# Other useful CPU memory counters are Bufferes and Cached (there are many other useful counters see /proc/meminfo


# Build the API signature
def build_signature(customer_id, shared_key, date, content_length, method, content_type, resource):
    x_headers = 'x-ms-date:' + date
    string_to_hash = method + "\n" + str(content_length) + "\n" + content_type + "\n" + x_headers + "\n" + resource
    bytes_to_hash = bytes(string_to_hash, encoding="utf-8")  
    decoded_key = base64.b64decode(shared_key)
    encoded_hash = base64.b64encode(hmac.new(decoded_key, bytes_to_hash, digestmod=hashlib.sha256).digest()).decode()
    authorization = "SharedKey {}:{}".format(customer_id,encoded_hash)
    return authorization


# Build and send a request to the POST API
def post_data(customer_id, shared_key, body, name_log_event):
    method = 'POST'
    content_type = 'application/json'
    resource = '/api/logs'
    rfc1123date = datetime.datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S GMT')
    content_length = len(body)
    signature = build_signature(customer_id, shared_key, rfc1123date, content_length, method, content_type, resource)
    uri = 'https://' + customer_id + '.ods.opinsights.azure.com' + resource + '?api-version=2016-04-01'

    headers = {
        'content-type': content_type,
        'Authorization': signature,
        'Log-Type': name_log_event,
        'x-ms-date': rfc1123date
    }

    response = requests.post(uri,data=body, headers=headers)
    if (response.status_code >= 200 and response.status_code <= 299):
        print('Accepted')
    else:
        print("Response code: {}".format(response.status_code))


def execute_cmd(cmd_l):
    proc = subprocess.Popen(cmd_l, stdout=subprocess.PIPE, universal_newlines=True)
    cmd_out, errs = proc.communicate()
    return cmd_out


def find_long_field_name(field_name,dcgm_dmon_list_out):
    for line in dcgm_dmon_list_out.splitlines():
        line_split = line.split()
        if field_name in line:
           return line_split[0]


def num(s):
    try:
       return int(s)
    except ValueError:
       return float(s)


def create_data_records(gpu_l, ib_rates_l, eth_rates_l, nfs_rates_l, disk_l, inode_l, cpu_mem_l, cpu_l, event_l):
    data_l = []
    if gpu_l:
       data_l = data_l + gpu_l
    if ib_rates_l:
       data_l = data_l + ib_rates_l
    if eth_rates_l:
       data_l = data_l + eth_rates_l
    if nfs_rates_l:
       data_l = data_l + nfs_rates_l
    if disk_l:
       data_l = data_l + disk_l
    if inode_l:
       data_l = data_l + inode_l
    if cpu_mem_l:
       data_l = data_l + cpu_mem_l
    if cpu_l:
       data_l = data_l + cpu_l
    if event_l:
       data_l = data_l + event_l

    return data_l


def get_slurm_jobid():
    if os.path.isdir('/sys/fs/cgroup/memory/slurm'):
      file_l = glob.glob('/sys/fs/cgroup/memory/slurm/uid_*/job_*')
      if file_l:
         jobid = int(file_l[0].split("_")[2])
         return (True, jobid)
      else:
         return (False, None)
    else:
      return (False, None)


def get_physicalhostname():

    file_path='/var/lib/hyperv/.kvp_pool_3'
    fileSize = os.path.getsize(file_path)
    num_kv = int(fileSize /(512+2048))
    file = open(file_path,'rb')
    for i in range(0, num_kv):
        key, value = struct.unpack("512s2048s",file.read(2560))
        key = key.split(b'\x00')
        value = value.split(b'\x00')
        if "PhysicalHostNameFullyQualified" in str(key[0]):
           return str(value[0])[2:][:-1]


def get_counter_value(file_path):
    file = open(file_path, "r")
    value = file.read()
    file.close()
    return int(value)


def counter_rate(current_counter, previous_counter, time_interval):
    counter_delta = current_counter - previous_counter
    if counter_delta < 0:
        counter_rate = int((2*64 + counter_delta) / time_interval)
    else:
        counter_rate = int(counter_delta / time_interval)
    return counter_rate


def get_infiniband_counter_rates(ib_counters, time_interval_seconds, hostname, physicalhostname_val, have_jobid, slurm_jobid):
    ib_counter_rates_l = []
    ib_base_path = '/sys/class/infiniband'
    for hca_id in os.listdir(ib_base_path):
        if hca_id not in ib_counters:
           ib_counters[hca_id] = {}
        ib_counter_rates = {}
        ib_counter_rates['hca_id'] = hca_id
        port = os.listdir(os.path.join(ib_base_path, hca_id, 'ports'))[0]
        ib_counter_base_path = os.path.join(ib_base_path, hca_id, 'ports', port, 'counters')
        for ib_counter_name in IB_COUNTERS:
            ib_counter_name_per_sec = ib_counter_name + "_" + "per_sec"
            ib_counter_path = os.path.join(ib_counter_base_path, ib_counter_name)
            current_ib_counter = get_counter_value(ib_counter_path)
            if ib_counter_name in ib_counters[hca_id]:
               ib_counter_rates[ib_counter_name_per_sec] = counter_rate(current_ib_counter, ib_counters[hca_id][ib_counter_name], time_interval_seconds)
            else:
               ib_counter_rates[ib_counter_name_per_sec] = 0
            ib_counters[hca_id][ib_counter_name] = current_ib_counter
        ib_counter_rates['hostname'] = hostname
        ib_counter_rates['physicalhostname'] = physicalhostname_val
        if have_jobid:
           ib_counter_rates['slurm_jobid'] = slurm_jobid
        ib_counter_rates_l.append(ib_counter_rates)
    return ib_counter_rates_l


def get_ethernet_counter_rates(eth_counters, time_interval_seconds, hostname, physicalhostname_val, have_jobid, slurm_jobid):
    eth_counter_rates_l = []
    eth_base_path = '/sys/class/net'
    for eth_device in os.listdir(eth_base_path):
        if eth_device.startswith('eth'):
           if eth_device not in eth_counters:
              eth_counters[eth_device] = {}
           eth_counter_rates = {}
           eth_counter_rates['eth_device'] = eth_device
           eth_counter_base_path = os.path.join(eth_base_path, eth_device, 'statistics')
           for eth_counter_name in ETH_COUNTERS:
               eth_counter_name_per_sec = eth_counter_name + "_" + "per_sec"
               eth_counter_path = os.path.join(eth_counter_base_path, eth_counter_name)
               current_eth_counter = get_counter_value(eth_counter_path)
               if eth_counter_name in eth_counters[eth_device]:
                  eth_counter_rates[eth_counter_name_per_sec] = counter_rate(current_eth_counter, eth_counters[eth_device][eth_counter_name], time_interval_seconds)
               else:
                  eth_counter_rates[eth_counter_name_per_sec] = 0
               eth_counters[eth_device][eth_counter_name] = current_eth_counter
           eth_counter_rates['hostname'] = hostname
           eth_counter_rates['physicalhostname'] = physicalhostname_val
           if have_jobid:
              eth_counter_rates['slurm_jobid'] = slurm_jobid
           eth_counter_rates_l.append(eth_counter_rates)
    return eth_counter_rates_l


def get_nfs_data():
    nfs_d = {}
    cmd_l = ['mountstats', '-R']
    mountstats_out = execute_cmd(cmd_l)
    mountstats_out_l = mountstats_out.splitlines()
    for line in mountstats_out_l:
        line_split = line.split()
        if "device" in line:
           nfs_mount_pt = line_split[4]
           nfs_d[nfs_mount_pt] = {}
        if "READ:" in line:
           client_read_iop = line_split[1]
           client_read_bytes = line_split[5]
           nfs_d[nfs_mount_pt]["client_read_iop"] = int(client_read_iop)
           nfs_d[nfs_mount_pt]["client_read_bytes"] = int(client_read_bytes)
        if "WRITE:" in line:
           client_write_iop = line_split[1]
           client_write_bytes = line_split[4]
           nfs_d[nfs_mount_pt]["client_write_iop"] = int(client_write_iop)
           nfs_d[nfs_mount_pt]["client_write_bytes"] = int(client_write_bytes)
    return nfs_d


def run_df_inode():
    df_d = {}
    cmd_l = ['df', '-i']
    df_out = execute_cmd(cmd_l)
    df_out_l = df_out.splitlines()
    for line in df_out_l:
        line_split = line.split()
        filesystem = line_split[0]
        inode_used_pc = line_split[4]
        if filesystem == "Filesystem" or inode_used_pc == "-":
           continue
        df_d[filesystem] = {}
        inode_total = line_split[1]
        inode_used = line_split[2]
        inode_free = line_split[3]
        mount_pt = line_split[5]
        df_d[filesystem]["inode_total"] = int(inode_total)
        df_d[filesystem]["inode_used"] = int(inode_used)
        df_d[filesystem]["inode_free"] = int(inode_free)
        df_d[filesystem]["inode_used_pc"] = int(inode_used_pc[:-1])
    return df_d


def get_inode_data(hostname, physicalhostname_val, have_jobid, slurm_jobid):
    inode_l = []
    df_inode_d = run_df_inode()
    for filesystem in df_inode_d:
        inode_d = {}
        inode_d['hostname'] = hostname
        inode_d['physicalhostname'] = physicalhostname_val
        if have_jobid:
           inode_d['slurm_jobid'] = slurm_jobid
        inode_d["inode_filesystem"] = filesystem
        inode_d["inode_total"] = df_inode_d[filesystem]["inode_total"]
        inode_d["inode_used"] = df_inode_d[filesystem]["inode_used"]
        inode_d["inode_free"] = df_inode_d[filesystem]["inode_free"]
        inode_d["inode_used_pc"] = df_inode_d[filesystem]["inode_used_pc"]
        inode_l.append(inode_d)
    return inode_l


def get_nfs_rates(nfs_counters, time_interval_seconds, hostname, physicalhostname_val, have_jobid, slurm_jobid):
    nfs_rates_l = []
    current_nfs_counters = get_nfs_data()
    if nfs_counters:
       for mount_pt in nfs_counters:
           nfs_rates = {}
           nfs_rates["nfs_mount_pt"] = mount_pt
           current_nfs_counters = get_nfs_data()
           nfs_rates["client_read_bytes_per_sec"] = counter_rate(current_nfs_counters[mount_pt]["client_read_bytes"], nfs_counters[mount_pt]["client_read_bytes"], time_interval_seconds)
           nfs_rates["client_read_iops"] = counter_rate(current_nfs_counters[mount_pt]["client_read_iop"], nfs_counters[mount_pt]["client_read_iop"], time_interval_seconds)
           nfs_rates["client_write_bytes_per_sec"] = counter_rate(current_nfs_counters[mount_pt]["client_write_bytes"], nfs_counters[mount_pt]["client_write_bytes"], time_interval_seconds)
           nfs_rates["client_write_iops"] = counter_rate(current_nfs_counters[mount_pt]["client_write_iop"], nfs_counters[mount_pt]["client_write_iop"], time_interval_seconds)
           nfs_rates['hostname'] = hostname
           nfs_rates['physicalhostname'] = physicalhostname_val
           if have_jobid:
              nfs_rates['slurm_jobid'] = slurm_jobid
           nfs_rates_l.append(nfs_rates)
           nfs_counters[mount_pt]["client_read_bytes"] = current_nfs_counters[mount_pt]["client_read_bytes"]
           nfs_counters[mount_pt]["client_read_iop"] = current_nfs_counters[mount_pt]["client_read_iop"]
           nfs_counters[mount_pt]["client_write_iop"] = current_nfs_counters[mount_pt]["client_write_iop"]
           nfs_counters[mount_pt]["client_write_bytes"] = current_nfs_counters[mount_pt]["client_write_bytes"]
    else:
        for mount_pt in current_nfs_counters:
            if mount_pt not in nfs_counters:
               nfs_counters[mount_pt] = {}
            nfs_rates = {}
            nfs_rates["nfs_mount_pt"] = mount_pt
            nfs_rates["client_read_bytes_per_sec"] = 0
            nfs_rates["client_write_bytes_per_sec"] = 0
            nfs_rates["client_read_iops"] = 0
            nfs_rates["client_write_iops"] = 0
            nfs_rates['hostname'] = hostname
            nfs_rates['physicalhostname'] = physicalhostname_val
            if have_jobid:
               nfs_rates['slurm_jobid'] = slurm_jobid
            nfs_rates_l.append(nfs_rates)
            nfs_counters[mount_pt]["client_read_bytes"] = current_nfs_counters[mount_pt]["client_read_bytes"]
            nfs_counters[mount_pt]["client_read_iop"] = current_nfs_counters[mount_pt]["client_read_iop"]
            nfs_counters[mount_pt]["client_write_iop"] = current_nfs_counters[mount_pt]["client_write_iop"]
            nfs_counters[mount_pt]["client_write_bytes"] = current_nfs_counters[mount_pt]["client_write_bytes"]

    return nfs_rates_l


def confirm_scheduled_event(event_id):
    payload = json.dumps({"StartRequests": [{"EventId": event_id }]})
    response = requests.post(metadata_url,
                            headers= header,
                            params = query_params,
                            data = payload)
    return response.status_code


def get_scheduled_events_data(last_DocumentIncarnation):
    events_l =[]
    metadata_scheduledevents_url ="http://169.254.169.254/metadata/scheduledevents"
    scheduledevents_header = {'Metadata' : 'true'}
    scheduledevents_params = {'api-version':'2020-07-01'}

    resp = requests.get(metadata_scheduledevents_url, headers = scheduledevents_header, params = scheduledevents_params)
    data = resp.json()
    current_DocumentIncarnation = data["DocumentIncarnation"]
  
    if current_DocumentIncarnation != last_DocumentIncarnation: 
       for event_d in data["Events"]:
           events_l.append(event_d)

    return events_l,current_DocumentIncarnation


def read_file(file_path):
    f = open(file_path, "r")
    file_lines_l = f.readlines()

    return file_lines_l


def find_line_in_file(find_string, file_lines_l):
    for line in file_lines_l:
        if line.find(find_string) >= 0:
            break
    return line


def find_value_in_file(find_string, index, file_lines_l):
    value = 0
    for line in file_lines_l:
        if line.find(find_string) >= 0:
            value = line.split()[index]
            break
    return int(value)


def find_value_in_line(line, index):
    return int(line.split()[index])


def find_str_in_line(line, index):
    return line.split()[index]


def get_gpu_data(dcgm_field_ids, hostname, physicalhostname_val, have_jobid, slurm_jobid):
    gpu_l = []
    gpu_field_name_l = []

    dcgm_dmon_fields_cmd_l = ['dcgmi', 'dmon', '-e', dcgm_field_ids, '-c', '1']
    dcgm_dmon_list_cmd_l = ['dcgmi', 'dmon', '-l']
    dcgm_dmon_fields_out = execute_cmd(dcgm_dmon_fields_cmd_l)
    dcgm_dmon_list_out = execute_cmd(dcgm_dmon_list_cmd_l)

    for line in dcgm_dmon_fields_out.splitlines():
        line_split = line.split()
        if 'Entity' in line:
           gpu_field_name_l = line_split[1:]
        if line_split[0] == 'GPU':
           record_d = {}
           record_d['gpu_id'] = int(line_split[1])
           record_d['hostname'] = hostname
           if have_jobid:
              record_d['slurm_jobid'] = slurm_jobid
           record_d['physicalhostname'] = physicalhostname_val
           for field_name in gpu_field_name_l:
               long_field_name = find_long_field_name(field_name,dcgm_dmon_list_out)
               indx = gpu_field_name_l.index(field_name) + 2
               record_d[long_field_name] = num(line_split[indx])
           gpu_l.append(record_d)

    return gpu_l


def get_cpu_mem_data(hostname, physicalhostname_val, have_jobid, slurm_jobid):
    cpu_mem_l = []
    cpu_mem_d = {}
    meminfo_l = read_file("/proc/meminfo")
    for cpu_mem_counter_name in CPU_MEM_COUNTERS:
        value = find_value_in_file(cpu_mem_counter_name, 1, meminfo_l)
        cpu_mem_d[cpu_mem_counter_name + "_KB"] = value
    if have_jobid:
        cpu_mem_d['slurm_jobid'] = slurm_jobid
    cpu_mem_d['hostname'] = hostname
    cpu_mem_d['physicalhostname'] = physicalhostname_val
    cpu_mem_l.append(cpu_mem_d)

    return cpu_mem_l


def get_cpu_loadavg_data():
    cpu_loadavg_l = []
    cpu_loadavg_l = read_file("/proc/loadavg")
    value = cpu_loadavg_l[0].split()[0]

    return value


def get_cpu_data(cpu_counters, hostname, physicalhostname_val, have_jobid, slurm_jobid):
    cpu_l = []
    cpu_d = {}
    stat_l = read_file("/proc/stat")
    cpu_line = find_line_in_file("cpu", stat_l)
    cpu_counters_l = ["user_time", "nice_time", "sys_time", "idle_time", "iowait_time", "irq_time", "softirq_time"]
    indx = 1
    for cpu_counter in cpu_counters_l:
        cpu_time = find_value_in_line(cpu_line, indx)
        cpu_key = "cpu_" + cpu_counter + "_user_hz"
        if cpu_counter in cpu_counters:
           cpu_d[cpu_key] = cpu_time - cpu_counters[cpu_counter]
        else:
           cpu_d[cpu_key] = 0
        cpu_counters[cpu_counter] = cpu_time
        indx = indx + 1

    if have_jobid:
        cpu_d['slurm_jobid'] = slurm_jobid
    cpu_d['hostname'] = hostname
    cpu_d['physicalhostname'] = physicalhostname_val
    cpu_d['loadavg'] = get_cpu_loadavg_data()
    cpu_l.append(cpu_d)

    return cpu_l


def get_disk_data(disk_counters, hostname, physicalhostname_val, have_jobid, slurm_jobid, time_interval_sec):
    disk_l = []
    disk_indx_l = [3, 5, 6, 7, 9, 10]
    diskstats_l = read_file("/proc/diskstats")
    disk_counters_l = ["read_completed", "read_sectors", "read_time_ms", "write_completed", "write_sectors", "write_time_ms"]
    for disk_line in diskstats_l:
        disk_d = {}
        disk_device_name = find_str_in_line(disk_line, 2)
        if "loop" in disk_device_name:
           continue
        disk_d['disk_name'] = disk_device_name
        disk_d['disk_time_interval_secs'] = time_interval_sec
        if disk_device_name not in disk_counters:
           disk_counters[disk_device_name] = {}
        indx = 0
        for disk_counter in disk_counters_l:
            disk_value = find_value_in_line(disk_line, disk_indx_l[indx])
            disk_key = "disk_" + disk_counter
            if disk_counter in disk_counters[disk_device_name]:
               disk_d[disk_key] = disk_value - disk_counters[disk_device_name][disk_counter]
            else:
               disk_d[disk_key] = 0
            disk_counters[disk_device_name][disk_counter] = disk_value
            indx = indx + 1

        if have_jobid:
           disk_d['slurm_jobid'] = slurm_jobid
        disk_d['hostname'] = hostname
        disk_d['physicalhostname'] = physicalhostname_val
        disk_l.append(disk_d)

    return disk_l


def read_env_vars():
    if 'customer_id' in globals():
       customer_id = globals()['customer_id']
    else:
       if 'LOG_ANALYTICS_CUSTOMER_ID' in os.environ:
          customer_id = os.environ['LOG_ANALYTICS_CUSTOMER_ID']
       else:
          sys.exit("Error: LOG_ANALYTICS_CUSTOMER_ID enviromental variable is not defined")
    if 'shared_key' in globals():
       shared_key = globals()['shared_key']
    else:
       if 'LOG_ANALYTICS_SHARED_KEY' in os.environ:
          shared_key = os.environ['LOG_ANALYTICS_SHARED_KEY']
       else:
          sys.exit("Error: LOG_ANALYTICS_SHARED_KEY enviromental variable is not defined")

    return (customer_id,shared_key)


def parse_args():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-dfi", "--dcgm_field_ids", dest="dcgm_field_ids", type=str, default="203,252,1004", help="Select the DCGM field ids you would like to monitor (if multiple field ids are desired then separate by commas) [string]")
    parser.add_argument("-nle", "--name_log_event", dest="name_log_event", type=str, default="MyGPUMonitor", help="Select a name for the log events you want to monitor")
    parser.add_argument("-fhm", "--force_hpc_monitoring", action="store_true", help="Forces data to be sent to log analytics WS even if no SLURM job is running on the node")
    parser.add_argument("-gpum", "--gpu_metrics", action="store_true", help="Collect GPU metrics")
    parser.add_argument("-ibm", "--infiniband_metrics", action="store_true", help="Collect InfiniBand metrics")
    parser.add_argument("-ethm", "--ethernet_metrics", action="store_true", help="Collect Ethernet metrics")
    parser.add_argument("-nfsm", "--nfs_metrics", action="store_true", help="Collect NFS client side metrics")
    parser.add_argument("-diskm", "--disk_metrics", action="store_true", help="Collect disk device metrics")
    parser.add_argument("-inodem", "--inode_metrics", action="store_true", help="Collect filesystem inode metrics")
    parser.add_argument("-cpum", "--cpu_metrics", action="store_true", help="Collects CPU metrics (e.g. user, sys, idle & iowait time)")
    parser.add_argument("-cpu_memm", "--cpu_mem_metrics", action="store_true", help="Collects CPU memory metrics (Default: MemTotal, MemFree)")
    parser.add_argument("-eventm", "--scheduled_event_metrics", action="store_true", help="Collects Azure/user scheduled events metrics")
    parser.add_argument("-uc", "--use_crontab", action="store_true", help="This script will be started by the system contab and the time interval between each data collection will be decided by the system crontab (if crontab is selected then the  -tis argument will be ignored).")
    parser.add_argument("-tis", "--time_interval_seconds", dest="time_interval_seconds", type=int, default=10, help="The time interval in seconds between each data collection (This option cannot be used with the -uc argument)")
    args = parser.parse_args()

    if args.gpu_metrics:
       gpu_metrics = True
    else:
       gpu_metrics = False
    if args.use_crontab:
       use_crontab = True
    else:
       use_crontab = False
    if args.infiniband_metrics:
       ib_metrics = True
    else:
       ib_metrics = False
    if args.ethernet_metrics:
       eth_metrics = True
    else:
       eth_metrics = False
    if args.nfs_metrics:
       nfs_metrics = True
    else:
       nfs_metrics = False
    if args.disk_metrics:
       disk_metrics = True
    else:
       disk_metrics = False
    if args.inode_metrics:
       inode_metrics = True
    else:
       inode_metrics = False
    if args.cpu_metrics:
       cpu_metrics = True
    else:
       cpu_metrics = False
    if args.cpu_mem_metrics:
       cpu_mem_metrics = True
    else:
       cpu_mem_metrics = False
    if args.scheduled_event_metrics:
       scheduled_event_metrics = True
    else:
       scheduled_event_metrics = False
    time_interval_seconds = args.time_interval_seconds
    dcgm_field_ids = args.dcgm_field_ids
    force_hpc_monitoring = args.force_hpc_monitoring
    name_log_event = args.name_log_event

    return (gpu_metrics,use_crontab,time_interval_seconds,dcgm_field_ids,force_hpc_monitoring,ib_metrics,eth_metrics,nfs_metrics,disk_metrics,inode_metrics,cpu_metrics,cpu_mem_metrics,scheduled_event_metrics,name_log_event)


def main():
    (gpu_metrics,use_crontab,time_interval_seconds,dcgm_field_ids,force_hpc_monitoring,ib_metrics,eth_metrics,nfs_metrics,disk_metrics,cpu_metrics,cpu_mem_metrics,scheduled_event_metrics,name_log_event) = parse_args()
    (customer_id,shared_key) = read_env_vars()
    ib_counters = {}
    cpu_counters = {}
    eth_counters = {}
    nfs_counters = {}
    disk_counters = {}
    ib_rates_l = []
    eth_rates_l = []
    nfs_rates_l = []
    disk_l = []
    inode_l = []
    cpu_mem_l = []
    cpu_l = []
    gpu_l = []
    event_l = []
    dcgm_dmon_fields_out = []
    dcgm_dmon_list_out = []
    last_DocumentIncarnation = -1

    while True:
          (have_jobid, slurm_jobid) = get_slurm_jobid()
          
          if have_jobid or force_hpc_monitoring:
             hostname = socket.gethostname()
             physicalhostname_val = get_physicalhostname()
             if gpu_metrics:
                gpu_l = get_gpu_data(dcgm_field_ids, hostname, physicalhostname_val, have_jobid, slurm_jobid)
             if ib_metrics:
                ib_rates_l = get_infiniband_counter_rates(ib_counters, time_interval_seconds, hostname, physicalhostname_val, have_jobid, slurm_jobid)
             if eth_metrics:
                eth_rates_l = get_ethernet_counter_rates(eth_counters, time_interval_seconds, hostname, physicalhostname_val, have_jobid, slurm_jobid)
             if nfs_metrics:
                nfs_rates_l = get_nfs_rates(nfs_counters, time_interval_seconds, hostname, physicalhostname_val, have_jobid, slurm_jobid)
             if cpu_mem_metrics:
                cpu_mem_l = get_cpu_mem_data(hostname, physicalhostname_val, have_jobid, slurm_jobid)
             if cpu_metrics:
                cpu_l = get_cpu_data(cpu_counters, hostname, physicalhostname_val, have_jobid, slurm_jobid)
             if disk_metrics:
                disk_l = get_disk_data(disk_counters, hostname, physicalhostname_val, have_jobid, slurm_jobid, time_interval_seconds)
             if inode_metrics:
                inode_l = get_inode_data(hostname, physicalhostname_val, have_jobid, slurm_jobid)
             if scheduled_event_metrics:
                event_l,last_DocumentIncarnation = get_scheduled_events_data(last_DocumentIncarnation)
             data_l = create_data_records(gpu_l, ib_rates_l, eth_rates_l, nfs_rates_l, disk_l, cpu_mem_l, cpu_l, event_l)
             print(data_l)
             if data_l:
                body = json.dumps(data_l)
                post_data(customer_id, shared_key, body, name_log_event)

          if use_crontab:
             break
          else:
             time.sleep(time_interval_seconds)


if __name__ == "__main__":
   main()

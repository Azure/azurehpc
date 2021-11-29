import json
import requests
import datetime
import hashlib
import hmac
import base64
import subprocess
import socket
import os
import glob
import struct

#110: sm_app_clock (expect 1410 on A100, assume MHz)
#110: mem_app_clock (expect 1215 on A100, assume MHz))
#150: gpu_temp (in C)
#203: gpu_utilization
#252: fb_used  (GPU memory used)
#1004: Tensor_active
#1006: fp64_active
#1007: fp32_active
#1008: fp16_active

dcgm_field_ids = '203,252,1004,1006,1007,1008'

# Update the customer ID to your Log Analytics workspace ID
customer_id = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'

# For the shared key, use either the primary or the secondary Connected Sources client authentication key   
shared_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# The log type is the name of the event that is being submitted
log_type = 'MYGPUMonitor'


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
def post_data(customer_id, shared_key, body, log_type):
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
        'Log-Type': log_type,
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


def find_long_field_name(field_name):
    for line in dcgm_dmon_list_out.splitlines():
        line_split = line.split()
        if field_name in line:
           return line_split[0]


def num(s):
    try:
       return int(s)
    except ValueError:
       return float(s)


def create_data_records():
    data_l = []
    field_name_l = []
    for line in dcgm_dmon_fields_out.splitlines():
        line_split = line.split()
        if 'Entity' in line:
           field_name_l = line_split[2:]
        if line_split[0] == 'GPU':
            record_d = {}
            record_d['gpu_id'] = int(line_split[1])
            record_d['hostname'] = hostname
            record_d['slurm_jobid'] = slurm_jobid
            record_d['physicalhostname'] = physicalhostname_val
            for field_name in field_name_l:
                long_field_name = find_long_field_name(field_name)
                indx = field_name_l.index(field_name) + 2
                record_d[long_field_name] = num(line_split[indx])
            data_l.append(record_d)
    return data_l


def get_slurm_jobid():
    if os.path.isdir('/sys/fs/cgroup/memory/slurm'):
      file_l = glob.glob('/sys/fs/cgroup/memory/slurm/uid_*/job_*')
      jobid = int(file_l[0].split("_")[2])
      return (True, jobid)
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



(have_jobid, slurm_jobid) = get_slurm_jobid()
if have_jobid:
   hostname = socket.gethostname()
   dcgm_dmon_fields_cmd_l = ['dcgmi', 'dmon', '-e', dcgm_field_ids, '-c', '1']
   dcgm_dmon_list_cmd_l = ['dcgmi', 'dmon', '-l']
   dcgm_dmon_fields_out = execute_cmd(dcgm_dmon_fields_cmd_l)
   dcgm_dmon_list_out = execute_cmd(dcgm_dmon_list_cmd_l)
   physicalhostname_val = get_physicalhostname()
   data_l = create_data_records()
   print(data_l)
   body = json.dumps(data_l)
   post_data(customer_id, shared_key, body, log_type)

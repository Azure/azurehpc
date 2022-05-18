#!/usr/bin/python3

import os
import struct
import socket

hostname = socket.gethostname()

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

def main():
    print("{} physicalhostname = {}".format(hostname,get_physicalhostname()))


if __name__ == "__main__":
       main()

#!/usr/bin/env python
import pbs
from os import path, mkdir, chmod, chown, sep, system
import pwd
from shutil import rmtree
import socket
import fcntl
import struct
import subprocess
import multiprocessing

def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        struct.pack('256s', ifname[:15])
    )[20:24])

e = pbs.event()
if e.type == pbs.EXECHOST_STARTUP:
    pbs.logmsg(pbs.EVENT_DEBUG, "EXECHOST_STARTUP event")
    wa_fin=open("/var/log/waagent.log")
    wa_data=wa_fin.read()
    wa_fin.close()
    if wa_data.find("Found RDMA details") == -1:
        pbs.accept()
    if wa_data.find("provisioning SRIOV RDMA device") != -1:
        pbs.logmsg(pbs.EVENT_DEBUG, "SRIOV RDMA enabled device")
        try:
            pbs.logmsg(pbs.EVENT_DEBUG, get_ip_address('ib0'))
        except IOError:
            pbs.logmsg(pbs.EVENT_DEBUG, "ib0: not found")
            # Search the waagent logs and see if RDMA is enabled
            wa_fin=open("/var/log/waagent.log")
            wa_data=wa_fin.readlines()
            wa_fin.close()
            for line in wa_data:
                if line.find("Found RDMA details") != -1:
                    ib0_ip = line.split(" ")[6]
                    ib0_ip = ib0_ip.split("=")[-1]
                    break
            pbs.logmsg(pbs.EVENT_DEBUG, "ib0 IP: %s" % ib0_ip)
        
            # If found do the following
            process = subprocess.Popen(['/sbin/ifup', 'ib0'], stdout=subprocess.PIPE)
            out, err = process.communicate()
            pbs.logmsg(pbs.EVENT_DEBUG, "stdout: %s" % out)
            pbs.logmsg(pbs.EVENT_DEBUG, "stderr: %s" % err)
            process = subprocess.Popen(['/sbin/ifconfig', 'ib0', ib0_ip], stdout=subprocess.PIPE)
            out, err = process.communicate()
            pbs.logmsg(pbs.EVENT_DEBUG, "stdout: %s" % out)
            pbs.logmsg(pbs.EVENT_DEBUG, "stderr: %s" % err)

            # Check to see if ib0 is back up
            try:
                pbs.logmsg(pbs.EVENT_DEBUG, get_ip_address('ib0'))
            except IOError:
                pbs.logmsg(pbs.EVENT_DEBUG, "Offline the node")
                # Offline the node
                vnlist = pbs.event().vnode_list
                hostname=pbs.get_local_nodename()
                pbs.logmsg(pbs.EVENT_DEBUG, "Offline hostname")
                for v in vnlist.keys():
                    pbs.logmsg(pbs.EVENT_DEBUG, "Node: %s" % v)
                    vnlist[v].state = pbs.ND_OFFLINE
                    vnlist[v].comment = "No ib0 on node"
                    pbs.event().reject("No IB on node")
    else: 
        try:
            pbs.logmsg(pbs.EVENT_DEBUG, get_ip_address('eth1'))
        except IOError:
            pbs.logmsg(pbs.EVENT_DEBUG, "eth1: not found")
            # Search the waagent logs and see if RDMA is enabled
            wa_fin=open("/var/log/waagent.log")
            wa_data=wa_fin.readlines()
            wa_fin.close()
            for line in wa_data:
                if line.find("Found RDMA details") != -1:
                    eth1_ip = line.split(" ")[6]
                    eth1_ip = eth1_ip.split("=")[-1]
                    break
            pbs.logmsg(pbs.EVENT_DEBUG, "eth1 IP: %s" % eth1_ip)
        
            # If found do the following
            process = subprocess.Popen(['/sbin/ifup', 'eth1'], stdout=subprocess.PIPE)
            out, err = process.communicate()
            pbs.logmsg(pbs.EVENT_DEBUG, "stdout: %s" % out)
            pbs.logmsg(pbs.EVENT_DEBUG, "stderr: %s" % err)
            process = subprocess.Popen(['/sbin/ifconfig', 'eth1', eth1_ip], stdout=subprocess.PIPE)
            out, err = process.communicate()
            pbs.logmsg(pbs.EVENT_DEBUG, "stdout: %s" % out)
            pbs.logmsg(pbs.EVENT_DEBUG, "stderr: %s" % err)

            # Check to see if eth1 is back up
            try:
                pbs.logmsg(pbs.EVENT_DEBUG, get_ip_address('eth1'))
            except IOError:
                pbs.logmsg(pbs.EVENT_DEBUG, "Offline the node")
                # Offline the node
                vnlist = pbs.event().vnode_list
                hostname=pbs.get_local_nodename()
                pbs.logmsg(pbs.EVENT_DEBUG, "Offline hostname")
                for v in vnlist.keys():
                    pbs.logmsg(pbs.EVENT_DEBUG, "Node: %s" % v)
                    vnlist[v].state = pbs.ND_OFFLINE
                    vnlist[v].comment = "No eth1 on node"
                    pbs.event().reject("No IB on node")

#!/usr/bin/env python
import pbs
from os import path, mkdir, chmod, chown, sep, symlink, unlink
import time
import pwd
from shutil import rmtree
import socket
import fcntl
import struct
import traceback
import subprocess
import sys
import multiprocessing


e = pbs.event()

def create_dir(dir_name, uid, gid):
    pbs.logmsg(pbs.EVENT_DEBUG, "Entering function: %s" % caller_name())
    base_path = path.dirname(dir_name)
    try:
        if not path.isdir(base_path):
            mkdir(base_path, 0o770)
        if not path.isdir(dir_name):
            mkdir(dir_name, 0o770)
            chown(dir_name, uid, gid)
        else:
            pbs.logmsg(pbs.EVENT_DEBUG, "Dir already exists: %s" % dir_name)
        return True
    except:
        pbs.logmsg(pbs.EVENT_DEBUG, "Something when wrong in the create_dir function")
        pbs.logmsg(pbs.EVENT_DEBUG, "Parameters: %s %s %s" % (dir_name, uid, gid))
        return False


def caller_name():
    """
        Return the name of the calling function or method.
    """
    return str(sys._getframe(1).f_code.co_name)

def run_cmd(cmd):
    # Get job substate based on printjob output
    try:
        pbs.logmsg(pbs.EVENT_DEBUG, "cmd: %s" % cmd)
        # Collect the job substate information
        process = subprocess.Popen(cmd, shell=False,
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        out, err = process.communicate()
        pbs.logmsg(pbs.EVENT_DEBUG, "%s: Output: %s" % (caller_name(), out))
        pbs.logmsg(pbs.EVENT_DEBUG, "%s: Error: %s" % (caller_name(), err))
        pbs.logmsg(pbs.EVENT_DEBUG, "%s: Return Code: %s" % (caller_name(), process.returncode))
        return([out, err])
    except Exception as exc:
        pbs.logmsg(pbs.EVENT_DEBUG, "%s: Unexpected error: %s" %
                   (caller_name, exc))
        pbs.logmsg(pbs.EVENT_DEBUG, str(traceback.format_exc().strip().splitlines()))
        return(False)

#if e.type == pbs.EXECHOST_STARTUP:
#    try: 
#        pbs.logmsg(pbs.EVENT_DEBUG, "EXECHOST_STARTUP event")
#
#        # Is NFS server installed
#        cmd = "rpm -qa | grep nfs-utils"
#        #cmd = cmd.split()
#        #out, err = run_cmd(cmd)
#        out = subprocess.check_output(cmd, shell=True)
#        out = out.split("\n")
#        pbs.logmsg(pbs.EVENT_DEBUG, "Lines: %s, RPM output: %s" % (len(out), out))
#
#    except:
#        pbs.logmsg(pbs.EVENT_DEBUG, str(traceback.format_exc().strip().splitlines()))
#    e.accept()


# Location to create tmp dir for the job on the compute node
j = e.job
NFS_DIR_NAME = "shared_%s" % j.id
NFS_MOUNT_POINT = "/mnt"
NFS_SSD_MOUNT_POINT = "/mnt/resource"
NFS_NVME_MOUNT_POINT = "/mnt/resource_nvme"
NFS_EXPORT_OPTIONS = "*(rw,async,no_root_squash)"
NFS_MOUNT_OPTIONS = "-o bg,rw,hard,noatime,nolock,rsize=65536,wsize=65536,vers=3"

mount_dir = NFS_MOUNT_POINT + sep + NFS_DIR_NAME
ib_addr_file = j.Variable_List["PBS_O_HOME"] + sep + j.id + "ms_mom_ib.out"

NFS_SERVICES = [
    "rpcbind",
    "nfs-server",
    "nfs-lock",
    "nfs-idmap",
    "nfs"
]


try:
    pbs.logmsg(pbs.EVENT_DEBUG, "Setup/Cleanup dedicated NFS disk for job")
    disk_type = None
    network_type = "eth" 
    env_name = "PBS_LOCAL_SHARED_DISK"
    # Check if job requested a shared local disk for the job
    if env_name in j.Variable_List:
        disk_type = j.Variable_List[env_name].lower()
        if disk_type not in ["ssd", "nvme"]:
            e.reject("disk_type: %s needs to be either ssd or nvme" % disk_type)
        else:
            pbs.logmsg(pbs.EVENT_DEBUG, "Setup local shared disk on the %s disk" % disk_type)

        env_name = "PBS_LOCAL_SHARED_DISK_NETWORK"
        # Check if job requested a shared local disk for the job
        if env_name in j.Variable_List:
            network_type = j.Variable_List[env_name].lower()
            if network_type not in ["eth", "ib"]:
                e.reject("network_type: %s needs to be either eth or ib" % network_type)
            else:
                pbs.logmsg(pbs.EVENT_DEBUG, "Setup NFS on the %s network" % network_type)
    else:
        pbs.logmsg(pbs.EVENT_DEBUG, "No local shared disk requested")
        e.accept()

    if e.type == pbs.EXECJOB_BEGIN:
        pbs.logmsg(pbs.EVENT_DEBUG, "EXECJOB_BEGIN event")

        # Get the user information
        user = j.euser
        uid=""
        gid=""
        try:
            uid = pwd.getpwnam(user).pw_uid
            gid = pwd.getpwnam(user).pw_gid
        except KeyError:
            pbs.logmsg(pbs.EVENT_DEBUG, "Failed to get uid for: %s" % user)
            pbs.logmsg(pbs.EVENT_DEBUG, "Wait 5s and try again")
            time.sleep(5)
            try:
                uid = pwd.getpwnam(user).pw_uid
                gid = pwd.getpwnam(user).pw_gid
            except KeyError:
                pbs.logmsg(pbs.EVENT_DEBUG, "Failed to get uid for: %s" % user)
                e.reject("Failed to get uid for %s" % user)

        # Create the directory to mount and the mount point
        pbs.logmsg(pbs.EVENT_DEBUG, "disk_type: %s, %s" % (disk_type, type(disk_type)))
        export_dir = None
        if disk_type == "ssd":
            pbs.logmsg(pbs.EVENT_DEBUG, "Creating directory on the SSD")
            export_dir = NFS_SSD_MOUNT_POINT + sep + NFS_DIR_NAME
        elif disk_type == "nvme":
            pbs.logmsg(pbs.EVENT_DEBUG, "Creating directory on the NVME")
            export_dir = NFS_NVME_MOUNT_POINT + sep + NFS_DIR_NAME
        else:
            e.reject("Unsupported disk_type: %s" % disk_type)
                    
        # Setup NFS server on mother superior
        if e.job.in_ms_mom():
            pbs.logmsg(pbs.EVENT_DEBUG, "On MS mom")
            
            pbs.logmsg(pbs.EVENT_DEBUG, "Creating shared directory: %s" % export_dir)
            status = create_dir(export_dir, uid, gid)
            if status is False:
                e.reject("Unable to create directory: %s" % export_dir)

            # Setup the exports file
            pbs.logmsg(pbs.EVENT_DEBUG, "Modifying the /etc/exports file")

            exports_file = "/etc/exports"
            outf = open(exports_file, "w")
            outf.write("%s %s" % (export_dir, NFS_EXPORT_OPTIONS))
            outf.close()

            cmd = "/usr/sbin/exportfs -a".split()
            out, err = run_cmd(cmd)

            # Tune the nfs settings
            cores = multiprocessing.cpu_count()
            pbs.logmsg(pbs.EVENT_DEBUG, "Cores: %s" % cores)
            nfs_procs = int(cores)
            
            nfs_in = open("/etc/sysconfig/nfs", "rt")
            data = nfs_in.read()
            data = data.replace("#RPCNFSDCOUNT=16", "RPCNFSDCOUNT=%d" % nfs_procs)
            nfs_in.close()

            nfs_out = open("/etc/sysconfig/nfs", "wt")
            nfs_out.write(data)
            nfs_out.close()

            # Start the nfs services
            for service in NFS_SERVICES:
                cmd = "systemctl restart %s" % service
                cmd = cmd.split()
                out, err = run_cmd(cmd)

            # Link the shared directory to the mount point
            symlink(export_dir, mount_dir)

            # Check to see if the ib address is needed
            pbs.logmsg(pbs.EVENT_DEBUG, "NFS network: %s" % (network_type))
            if network_type == "ib":
                cmd = "/sbin/ifconfig ib0"
                cmd = cmd.split()
                out, err = run_cmd(cmd)

                lines = out.split("\n")
                ib_addr = lines[1].split()[1]
                pbs.logmsg(pbs.EVENT_DEBUG, "MS Node IB Addr: %s" % (ib_addr))

                # Write ib address to a file in the user home directory
                outfile = open(ib_addr_file, "w")  
                outfile.write(ib_addr)
                outfile.close()
            
        else:
            pbs.logmsg(pbs.EVENT_DEBUG, "On sister mom")

            # Create the directory to mount and the mount point
            pbs.logmsg(pbs.EVENT_DEBUG, "Creating mount point")
            status = create_dir(mount_dir, uid, gid)

            # Find the MS node name
            ms_node = j.exec_host2.split(":")[0]
            ms_node = ms_node.split(".")[0]
            pbs.logmsg(pbs.EVENT_DEBUG, "MS Node: %s" % ms_node)

            if network_type == "ib":
                infile = open(ib_addr_file)
                ib_addr = infile.read().split("\n")[0]
                pbs.logmsg(pbs.EVENT_DEBUG, "MS Node: %s" % ib_addr)
                ms_node = ib_addr

                

            # Mount the shared disk
            cmd = "mount %s:%s %s %s" % (ms_node, export_dir, mount_dir, NFS_MOUNT_OPTIONS)
            cmd = cmd.split()
            out, err = run_cmd(cmd)


    # Clean up on job exit
    elif e.type == pbs.EXECJOB_EPILOGUE:
        pbs.logmsg(pbs.EVENT_DEBUG, "EXECJOB_EPILOGUE event")
        if not e.job.in_ms_mom():
            pbs.logmsg(pbs.EVENT_DEBUG, "Clean up sister mom")
            
            # Unmount and clean up directories
            cmd = "umount -f %s" % mount_dir
            cmd = cmd.split()
            out, err = run_cmd(cmd)

            # Remove the directory created for the mount point
            dir_list = [mount_dir]
            for dir_name in dir_list:
                if path.isdir(dir_name):
                    pbs.logmsg(pbs.EVENT_DEBUG, "Removing: %s" % dir_name)
                    rmtree(dir_name)

    elif e.type == pbs.EXECJOB_END:
        pbs.logmsg(pbs.EVENT_DEBUG, "EXECJOB_END event")

        if e.job.in_ms_mom():
            pbs.logmsg(pbs.EVENT_DEBUG, "Clean up MS mom")
            # Shut down the nfs services and clean up exports file
            for service in NFS_SERVICES:
                cmd = "systemctl stop %s" % service
                cmd = cmd.split()
                out, err = run_cmd(cmd)

            # Remove the symbolic link
            unlink(NFS_MOUNT_POINT + sep + NFS_DIR_NAME)

            # Clean up directories mount points
            dir_list = [
                NFS_SSD_MOUNT_POINT + sep + NFS_DIR_NAME,
                NFS_NVME_MOUNT_POINT + sep + NFS_DIR_NAME
            ]
            for dir_name in dir_list:
                if path.isdir(dir_name):
                    pbs.logmsg(pbs.EVENT_DEBUG, "Removing: %s" % dir_name)
                    rmtree(dir_name)

            if path.isfile(ib_addr_file):
                pbs.logmsg(pbs.EVENT_DEBUG, "Removing IB address file: %s" % ib_addr_file)
                remove(ib_addr_file)
                
except:
    pbs.logmsg(pbs.EVENT_DEBUG, str(traceback.format_exc().strip().splitlines()))

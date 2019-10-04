#!/usr/bin/env python
import pbs
from os import path, mkdir, chmod, chown, sep
import time
import pwd
from shutil import rmtree
import socket
import fcntl
import struct

# Location to create tmp dir for the job on the compute node
base_loc = "/mnt/resource"

e = pbs.event()
if e.type == pbs.EXECJOB_BEGIN:
    pbs.logmsg(pbs.EVENT_DEBUG, "EXECJOB_BEGIN event")

    j = e.job
    pbs_conf = pbs.get_pbs_conf()
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

    # Create a local dir on the local disk
    if path.isdir(base_loc):
        new_dir = base_loc + sep + j.id
        if not path.isdir(new_dir):
            mkdir(new_dir, 0770)
            chown(new_dir, uid, gid)
        else:
            pbs.logmsg(pbs.EVENT_DEBUG, "Dir already exists: %s" % new_dir)
    else:
        pbs.logmsg(pbs.EVENT_DEBUG, "Unable to find: %s" % base_loc)

# Clean up local dir on job exit
elif e.type == pbs.EXECJOB_END:
    pbs.logmsg(pbs.EVENT_DEBUG, "EXECJOB_END event")
    j = e.job
    if path.isdir(base_loc + sep + j.id):
        pbs.logmsg(pbs.EVENT_DEBUG, "Removing: %s" % base_loc)
        rmtree(base_loc + sep + j.id)

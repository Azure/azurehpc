#!/usr/bin/env python
import pbs
import fcntl
import struct
import subprocess
import traceback

try:

    # Determine which linux distro you are using
    os_distro="centos"
    process = subprocess.Popen(['cat', '/etc/os-release'], stdout=subprocess.PIPE)
    out, err = process.communicate()
    out = out.decode()
    pbs.logmsg(pbs.EVENT_DEBUG, "stdout: %s" % out)
    lines = out.split("\n")
    for line in lines:
        if line[:3] == "ID=":
            os_distro = line.split("=")[1].replace('"',"")

    pbs.logmsg(pbs.EVENT_DEBUG, "OS Distro: %s" % os_distro)
    waagent = "waagent"
    if os_distro == "ubuntu":
        waagent = "walinuxagent"

    e = pbs.event()
    if e.type == pbs.EXECJOB_BEGIN:
        pbs.logmsg(pbs.EVENT_DEBUG, "EXECJOB_BEGIN event")
        pbs.logmsg(pbs.EVENT_DEBUG, "Stop Waagent")
        # If found do the following
        process = subprocess.Popen(['/bin/systemctl', 'stop', waagent], stdout=subprocess.PIPE)
        out, err = process.communicate()
        pbs.logmsg(pbs.EVENT_DEBUG, "stdout: %s" % out)
        pbs.logmsg(pbs.EVENT_DEBUG, "stderr: %s" % err)
    elif e.type == pbs.EXECJOB_END:
        pbs.logmsg(pbs.EVENT_DEBUG, "EXECJOB_END event")
        pbs.logmsg(pbs.EVENT_DEBUG, "Start Waagent")
        # If found do the following
        process = subprocess.Popen(['/bin/systemctl', 'start', waagent], stdout=subprocess.PIPE)
        out, err = process.communicate()
        pbs.logmsg(pbs.EVENT_DEBUG, "stdout: %s" % out)
        pbs.logmsg(pbs.EVENT_DEBUG, "stderr: %s" % err)

except Exception as exc:
    # Catch all other exceptions and report them, job gets held
    # and a stack trace is logged
    pbs.logmsg(pbs.EVENT_DEBUG, str(traceback.format_exc().strip().splitlines()))

#!/usr/bin/env python
import pbs
import fcntl
import struct
import subprocess

e = pbs.event()
if e.type == pbs.EXECJOB_BEGIN:
    pbs.logmsg(pbs.EVENT_DEBUG, "EXECJOB_BEGIN event")
    pbs.logmsg(pbs.EVENT_DEBUG, "Stop Waagent")
    # If found do the following
    process = subprocess.Popen(['/bin/systemctl', 'stop', 'waagent'], stdout=subprocess.PIPE)
    out, err = process.communicate()
    pbs.logmsg(pbs.EVENT_DEBUG, "stdout: %s" % out)
    pbs.logmsg(pbs.EVENT_DEBUG, "stderr: %s" % err)
elif e.type == pbs.EXECJOB_END:
    pbs.logmsg(pbs.EVENT_DEBUG, "EXECJOB_END event")
    pbs.logmsg(pbs.EVENT_DEBUG, "Start Waagent")
    # If found do the following
    process = subprocess.Popen(['/bin/systemctl', 'start', 'waagent'], stdout=subprocess.PIPE)
    out, err = process.communicate()
    pbs.logmsg(pbs.EVENT_DEBUG, "stdout: %s" % out)
    pbs.logmsg(pbs.EVENT_DEBUG, "stderr: %s" % err)

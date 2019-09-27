#!/usr/bin/env python
import pbs
import fcntl
import struct
import subprocess
from os import path
import traceback

e = pbs.event()
if e.type == pbs.EXECHOST_STARTUP:
    pbs.logmsg(pbs.EVENT_DEBUG, "EXECHOST_STARTUP event")
    pbs.logmsg(pbs.EVENT_DEBUG, "NHC run stream")
    # If found do the following
    if path.exists("/data/node_utils/Stream/stream_test.sh"):
        process = subprocess.Popen(['/data/node_utils/Stream/stream_test.sh'], stdout=subprocess.PIPE)
        out, err = process.communicate()
        pbs.logmsg(pbs.EVENT_DEBUG, "stdout: %s" % out)
        pbs.logmsg(pbs.EVENT_DEBUG, "stderr: %s" % err)
        pbs.logmsg(pbs.EVENT_DEBUG, "ReturnCode: %s" % process.returncode)
        if process.returncode != 0:
            try:
                pbs.logmsg(pbs.EVENT_ERROR, "Node failed the memory stream test.")
                # Get the node and offline it,
                comment="Failed memory stream test"
                hostname=pbs.get_local_nodename()
                pbs.logmsg(pbs.EVENT_DEBUG,"Offline node: %s"%(hostname))
                myvnode = pbs.event().vnode_list[hostname]
                myvnode.state = pbs.ND_OFFLINE
                pbs.logmsg(pbs.EVENT_DEBUG, "Offline node comment: %s" % comment)
                myvnode.comment =  "<-----nhc: " + comment
            except:
                pbs.logmsg(pbs.EVENT_ERROR, str(traceback.format_exc().strip().splitlines()))
        else:
            pbs.logmsg(pbs.EVENT_ERROR, "Passed the memory stream test. %s"%out)
    else:
       pbs.logmsg(pbs.EVENT_DEBUG, "Unable to find stream_test.sh in /data/node_utils/Stream dir")

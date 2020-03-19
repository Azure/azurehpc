#!/usr/bin/env python

import pbs
import subprocess
import traceback

e = pbs.event()

pbs.logmsg(pbs.EVENT_DEBUG, "Entering the cleanup hook")

if e.type in [pbs.EXECJOB_BEGIN, pbs.EXECJOB_END]:
    pbs.logmsg(pbs.EVENT_DEBUG, "EXECJOB_BEGIN or END event")

    # Find the job username
    j = e.job
    user = j.euser
    pbs.logmsg(pbs.EVENT_DEBUG, "Username: %s" % user )

    # Kill all of the username processes
    try:
        process = subprocess.Popen(['/usr/bin/pkill', '-9', '-u', '%s' % user], stdout=subprocess.PIPE)
        out, err = process.communicate()
        pbs.logmsg(pbs.EVENT_DEBUG, "stdout: %s" % out)
        pbs.logmsg(pbs.EVENT_DEBUG, "stderr: %s" % err)
    except Exception:
        pbs.logmsg(pbs.EVENT_DEBUG, "Cleanup hook failed to run as expected" )
        pbs.logmsg(pbs.EVENT_DEBUG, str(traceback.format_exc().strip().splitlines()))
else:
    pbs.logmsg(pbs.EVENT_DEBUG, "Not EXECJOB_BEGIN or END event")

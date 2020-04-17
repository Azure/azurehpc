#!/bin/bash

/opt/pbs/bin/qmgr -c "export hook pbs_cgroups application/x-config default" > pbs_cgroups.json

tmp=$(mktemp)
jq '.cgroup.devices.enabled = true' pbs_cgroups.json > $tmp && mv $tmp pbs_cgroups.json
jq '.cgroup.devices.allow = [ "b *:* rwm","c 10:* rwm","c 4:* rwm","c 5:* rwm","c 1:* rwm","c 7:* rwm",["nvidia-uvm", "rwm"]]' pbs_cgroups.json > $tmp && mv $tmp pbs_cgroups.json

/opt/pbs/bin/qmgr -c "import hook pbs_cgroups application/x-config default pbs_cgroups.json"

/opt/pbs/bin/qmgr -c "export hook pbs_cgroups application/x-python default" > pbs_cgroups.py

cat > pbs_cgroups_py.patch << EOF
--- pbs_cgroups.py_orig 2020-04-08 20:05:31.573683390 +0000
+++ pbs_cgroups.py      2020-04-08 20:09:50.388237101 +0000
@@ -780,6 +780,7 @@
                 if gpus:
                     # Don't put quotes around the values. ex "0" or "0,1".
                     # This will cause it to fail.
+                    gpus = [str(i) for i in range(0,len(gpus))]
                     env_list.append('CUDA_VISIBLE_DEVICES=%s' %
                                     string.join(gpus, ','))
             pbs.logmsg(pbs.EVENT_DEBUG4, 'ENV_LIST: %s' % env_list)
@@ -1014,6 +1015,7 @@
                 if gpus:
                     # Don't put quotes around the values. ex "0" or "0,1".
                     # This will cause it to fail.
+                    gpus = [str(i) for i in range(0,len(gpus))]
                     env_list.append('CUDA_VISIBLE_DEVICES=%s' %
                                     string.join(gpus, ','))
             pbs.logmsg(pbs.EVENT_DEBUG4, 'ENV_LIST: %s' % env_list)
@@ -2887,6 +2889,7 @@
                 pbs.logmsg(pbs.EVENT_DEBUG4,
                            'offload_devices: %s' % offload_devices)
             if cuda_visible_devices:
+                cuda_visible_devices = [str(i) for i in range(0,len(cuda_visible_devices))]
                 value = string.join(cuda_visible_devices, '\\\,')
                 pbs.event().env['CUDA_VISIBLE_DEVICES'] = '%s' % value
                 pbs.logmsg(pbs.EVENT_DEBUG4,
EOF

patch -p0 < pbs_cgroups_py.patch

/opt/pbs/bin/qmgr -c "import hook pbs_cgroups application/x-python default pbs_cgroups.py"

/opt/pbs/bin/qmgr -c "set hook pbs_cgroups enabled = true"

sed -i 's/^resources:.*/resources: "ncpus, pool_name, mem, arch, host, vnode, aoe, eoe, ngpus"/' /var/spool/pbs/sched_priv/sched_config

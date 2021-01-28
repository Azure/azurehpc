#!/bin/bash
# arg: $1 = pbs_server
pbs_server=$1

function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=3
  local delay=10
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}

if ! rpm -q pbspro-execution; then
    if ! rpm -q jq; then
        yum install -y jq
    fi

    yum install -y pbspro-execution-19.1.3-0.x86_64.rpm

    sed -i "s/CHANGE_THIS_TO_PBS_PRO_SERVER_HOSTNAME/${pbs_server}/g" /etc/pbs.conf
    sed -i "s/CHANGE_THIS_TO_PBS_PRO_SERVER_HOSTNAME/${pbs_server}/g" /var/spool/pbs/mom_priv/config
    sed -i "s/^if /#if /g" /opt/pbs/lib/init.d/limits.pbs_mom
    sed -i "s/^fi/#fi /g" /opt/pbs/lib/init.d/limits.pbs_mom
    systemctl enable pbs
    systemctl start pbs

    # Retrieve the VMSS name to be used as the pool name for multiple VMSS support
    poolName=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmScaleSetName')
    if [ -z "$poolName" ]; then
        echo "Unable to query MDS"
        poolName="compute"
    fi
    echo "Registering node for poolName $poolName"
    retry /opt/pbs/bin/qmgr -c "c n $(hostname) resources_available.pool_name='$poolName'"
else
    echo "PBS client was already installed"
fi

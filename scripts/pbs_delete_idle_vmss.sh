#!/bin/bash

IDLE_TIME_MINS=${1:-10}
DEBUG=${2:-1}

LOGFILE=/tmp/azurehpc_delete_idle_vmss.log_$$
SCRIPT_NAME=/tmp/azurehpc_delete_idle_vmss.sh
PBSNODES_JSON=/tmp/pbsnodes.json
NODES_JSON=/tmp/nodes.json
USER=hpcadmin

cat << EOF >> $SCRIPT_NAME
#!/bin/bash

echo >> $LOGFILE
CURRENT_TIME=\`date +%s\`
IDLE_TIME_SECS=$((IDLE_TIME_MINS*60))
node_list=""

function get_instance_id() 
{
    OLDIFS=\$IFS
    IFS="_"
    set -- \$1
    IFS=\$OLDIFS
    instanceid=\$2
}

echo "\`date\`: CURRENT_TIME=\$CURRENT_TIME" >> $LOGFILE

/opt/pbs/bin/pbsnodes -a -F json >& $PBSNODES_JSON
jq ".nodes | keys" $PBSNODES_JSON >& $NODES_JSON

for node in \`jq -r .[] $NODES_JSON\`
do
node_list="\$node_list \$node"
done
if [ $DEBUG -eq 1 ]; then
   echo "\`date\`: node_list=\$node_list" >> $LOGFILE
fi

for node in \$node_list
do
  echo >> $LOGFILE
  node_lut=\`jq "select(.nodes.\$node.last_used_time) | .nodes.\$node.last_used_time" $PBSNODES_JSON\`
  node_state=\`jq -r ".nodes.\$node.state" $PBSNODES_JSON\`
  if [ $DEBUG -eq 1 ]; then
     echo "\`date\`: VM \$node, PBS last used time = \$node_lut" >> $LOGFILE
     echo "\`date\`: VM \$node, PBS state = \$node_state" >> $LOGFILE
  fi
  if [ ! -z \$node_lut ] && [ \$node_state == "free" ]; then
    echo "\`date\`: Checking node=\$node" >> $LOGFILE
    DIFF=\$((CURRENT_TIME-node_lut))
    if [ $DEBUG -eq 1 ]; then
       echo "\`date\`: CURRENT_TIME=\$CURRENT_TIME,pbs node state=$node_state,node_lut=\$node_lut,DIFF=\$DIFF" >> $LOGFILE
    fi
    if [ \$DIFF -gt \$IDLE_TIME_SECS ]
    then
       eval ssh \$node curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq . >& /tmp/\${node}.json
       vmscalesetname=\`jq -r .vmScaleSetName /tmp/\${node}.json\`
       resourcegroupname=\`jq -r .resourceGroupName /tmp/\${node}.json\`
       resourceid=\`jq -r .resourceId /tmp/\${node}.json\`
        if [ $DEBUG -eq 1 ]; then
           echo "\`date\`: vmscalesetname=\$vmscalesetname,resourcegroupname=\$resourcegroupname,resourceid=\$resourceid" >> $LOGFILE
        fi
       get_instance_id \$resourceid
       if [ $DEBUG -eq 1 ]; then
          echo "\`date\`: VM=\$node corresponds to InstanceId=\$instanceid" >> $LOGFILE
       fi
       echo "\`date\`: removing $node from PBS" >> $LOGFILE
       sudo /opt/pbs/bin/qmgr -c "d n \$node"
       echo "\`date\`: Deleting instance \$node from vmss" >> $LOGFILE
       az vmss delete-instances --instance-ids \$instanceid --name \$vmscalesetname --resource-group \$resourcegroupname --no-wait
    fi
  fi
done
EOF

chmod 777 $SCRIPT_NAME

crontab -l > mycrontab
echo "*/$IDLE_TIME_MINS * * * * $SCRIPT_NAME" >> mycrontab
crontab mycrontab
crontab -l

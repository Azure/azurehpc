#!/bin/bash
export azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$azhpc_dir/libexec/common.sh"

DEBUG_ON=0
COLOR_ON=1
config_file="config.json"

function usage() {
    echo "Command:"
    echo "    $0 [options] <vmss-resource> <size>"
    echo
    echo "Arguments"
    echo "    -h --help  : diplay this help"
    echo "    -c --config: config file to use"
    echo "                 default: config.json"
    echo
}

while true; do
    case $1 in
        -h|--help)
        usage
        exit 0
        ;;
        -c|--config)
        config_file="$2"
        shift
        shift
        ;;
        *)
        break
    esac
done

if [ ! -f "$config_file" ]; then
    error "missing config file ($config_file)"
fi

local_script_dir="$(dirname $config_file)/scripts"

if [ "$#" -ne 2 ]; then
    error "incorrect number of arguments"
fi

vmss_resource=$1
vmss_target_size=$2
status "Resizing $vmss_resource to $vmss_target_size"

subscription="$(az account show --output tsv --query '[name,id]')"
subscription_name=$(echo "$subscription" | head -n1)
subscription_id=$(echo "$subscription" | tail -n1)
status "Azure account: $subscription_name ($subscription_id)"

read_value location ".location"
read_value resource_group ".resource_group"
read_value vnet_name ".vnet.name"
read_value address_prefix ".vnet.address_prefix"
read_value admin_user ".admin_user"
read_value install_node ".install_from"

#tmp_dir=build_$(date +%Y%m%d-%H%M%S)
config_file_no_path=${config_file##*/}
config_file_no_path_or_extension=${config_file_no_path%.*}
tmp_dir=azhpc_install_$config_file_no_path_or_extension
status "creating temp dir - $tmp_dir"
mkdir -p $tmp_dir

ssh_private_key=${admin_user}_id_rsa
ssh_public_key=${admin_user}_id_rsa.pub

# check vmss exists in config file
read_value check_resource .resources.$vmss_resource "<unknown>"
if [ "$check_resource" = "<unknown>" ]; then
    error "$vmss_resource is not in the config file"
fi
# get current vmss size
vmss_current_size=$( \
    az vmss show \
        --resource-group $resource_group \
        --name $vmss_resource \
        --output tsv \
        --query sku.capacity \
)
if [ "$vmss_current_size" = "$vmss_target_size" ]; then
    status "$vmss_resource is already at target size ($vmss_target_size)"
    exit 0
fi
# get current vmss hosts
az vmss list-instances \
    --resource-group $resource_group \
    --name $vmss_resource \
    --query [].osProfile.computerName \
    --output tsv \
    > $tmp_dir/$vmss_resource-hostlist.old

status "resizing $vmss_resource"
az vmss scale \
    --resource-group $resource_group \
    --name $vmss_resource \
    --output table \
    --new-capacity $vmss_target_size

# get new vmss hosts
az vmss list-instances \
    --resource-group $resource_group \
    --name $vmss_resource \
    --query [].osProfile.computerName \
    --output tsv \
    > $tmp_dir/$vmss_resource-hostlist

if [ "$vmss_target_size" -lt "$vmss_current_size" ]; then
    grep -Fxvf $tmp_dir/$vmss_resource-hostlist $tmp_dir/$vmss_resource-hostlist.old > $tmp_dir/$vmss_resource-hosts-removed
    status "Resize complete, hosts removed: $(cat $tmp_dir/$vmss_resource-hosts-removed | tr '\n' ',' | sed 's/,$//g')"
    exit 0
fi

# new hosts are added so create install
grep -Fxvf $tmp_dir/$vmss_resource-hostlist.old $tmp_dir/$vmss_resource-hostlist > $tmp_dir/$vmss_resource-hosts-added
status "hosts added: $(cat $tmp_dir/$vmss_resource-hosts-added | tr '\n' ',' | sed 's/,$//g')"

status "getting public ip for $install_node"
fqdn=$(
    az network public-ip show \
        --resource-group $resource_group \
        --name ${install_node}pip --query dnsSettings.fqdn \
        --output tsv \
        2>/dev/null \
)

if [ "$fqdn" = "" ]; then
    status "The install node does not have a public IP.  Using hostname - $install_node - and must be on this node must be on the same vnet"
fi

nsteps=$(jq -r ".install | length" $config_file)

if [ "$nsteps" -eq 0 ]; then

    status "no install steps"

else

    timestamp=$(date +%Y%m%d-%H%M%S)
    status "building install scripts - $nsteps steps"
    install_sh=$tmp_dir/resize-$vmss_resource-$vmss_target_size-$timestamp.sh

    cat <<OUTER_EOF > $install_sh
#!/bin/bash

cd ~/$tmp_dir

prsync -a -h $vmss_resource-hosts-added ~/$tmp_dir ~ > resize_${timestamp}_step_0_install_node_setup.log 2>&1
prsync -a -h $vmss_resource-hosts-added ~/.ssh ~ >> resize_${timestamp}_step_0_install_node_setup.log 2>&1

pssh -t 0 -i -h $vmss_resource-hosts-added 'echo "AcceptEnv PSSH_NODENUM PSSH_HOST" | sudo tee -a /etc/ssh/sshd_config' >> resize_${timestamp}_step_0_install_node_setup.log 2>&1
pssh -t 0 -i -h $vmss_resource-hosts-added 'sudo systemctl restart sshd' >> resize_${timestamp}_step_0_install_node_setup.log 2>&1
pssh -t 0 -i -h $vmss_resource-hosts-added "echo 'Defaults env_keep += \"PSSH_NODENUM PSSH_HOST\"' | sudo tee -a /etc/sudoers" >> resize_${timestamp}_step_0_install_node_setup.log 2>&1
OUTER_EOF

    for step in $(seq 1 $nsteps); do
        idx=$(($step - 1))

        read_value install_tag ".install[$idx].tag"
        resource_has_tag=$(jq ".resources.$vmss_resource.tags | index(\"$install_tag\")" $config_file)
        if [ "$resource_has_tag" = "null" ]; then
            status "skipping step $step as it doesn't apply to $vmss_resource"
            continue
        fi

        read_value install_script ".install[$idx].script"
        read_value install_reboot ".install[$idx].reboot" false
        read_value install_sudo ".install[$idx].sudo" false
        install_nfiles=$(jq -r ".install[$idx].copy | length" $config_file)

        install_script_arg_count=$(jq -r ".install[$idx].args | length" $config_file)
        install_command_line=$install_script
        if [ "$install_script_arg_count" -ne "0" ]; then
            for n in $(seq 0 $((install_script_arg_count - 1))); do
                read_value arg ".install[$idx].args[$n]"
                install_command_line="$install_command_line '$arg'"
            done
        fi

        echo "echo 'Step $step : $install_script'" >> $install_sh
        echo "start_time=\$SECONDS" >> $install_sh

        if [ "$install_nfiles" != "0" ]; then
            echo "## copying files" >>$install_sh
            for f in $(jq -r ".install[$idx].copy | @tsv" $config_file); do
                echo "pscp.pssh -h $vmss_resource-hosts-added $f \$(pwd) >> resize_${timestamp}_step_${step}_${install_script%.sh}.log 2>&1" >>$install_sh
            done
        fi

        sudo_prefix=
        if [ "$install_sudo" = "true" ]; then
            sudo_prefix=sudo
        fi

        # can run in parallel with pssh
        echo "pssh -t 0 -i -h $vmss_resource-hosts-added \"cd $tmp_dir; $sudo_prefix scripts/$install_command_line\" >> resize_${timestamp}_step_${step}_${install_script%.sh}.log 2>&1" >>$install_sh

        if [ "$install_reboot" = "true" ]; then
            cat <<EOF >> $install_sh
pssh -t 0 -i -h $vmss_resource-hosts-added "sudo reboot" >> resize_${timestamp}_step_${step}_${install_script%.sh}.log 2>&1
echo "    Waiting for nodes to come back"
sleep 10
for h in \$(<$vmss_resource-hosts-added); do
    nc -z \$h 22
    echo "        \$h rebooted"
done
sleep 10
EOF
        fi

        echo 'echo "    duration: $(($SECONDS - $start_time)) seconds"' >> $install_sh

    done

    chmod +x $install_sh
    cp $ssh_private_key $tmp_dir
    cp $ssh_public_key $tmp_dir
    cp -r $azhpc_dir/scripts $tmp_dir
    cp -r $local_script_dir/* $tmp_dir/scripts/. 2>/dev/null
    rsync -a -e "ssh $SSH_ARGS -i $ssh_private_key" $tmp_dir $admin_user@$fqdn:.

    status "running the install script $fqdn"
    ssh $SSH_ARGS -q -i $ssh_private_key $admin_user@$fqdn $install_sh

fi

status "cluster ready"

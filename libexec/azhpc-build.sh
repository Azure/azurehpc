#!/bin/bash
export azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$azhpc_dir/libexec/common.sh"

DEBUG_ON=0
COLOR_ON=1
config_file="config.json"

pssh_parallelism=50

function usage() {
    echo "Command:"
    echo "    $0 [options]"
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

unset_vars="$(jq -r '.variables | with_entries(select(.value=="<NOT-SET>")) | keys | join(", ")' $config_file 2>/dev/null)"
if [ "$unset_vars" != "" ]; then
    error "unset variables in config: $unset_vars"
fi

local_script_dir="$(dirname $config_file)/scripts"

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

if [ ! -e "$ssh_private_key" ]; then
    status "creating ssh keys for $admin_user"
    ssh-keygen -f $ssh_private_key -t rsa -N ''
fi

status "creating resource group"
az group create \
    --resource-group $resource_group \
    --location $location \
    --tags 'CreatedBy='$USER'' 'CreatedOn='$(date +%Y%m%d-%H%M%S)'' \
    --output table

status "creating network"
read_value vnet_resource_group ".vnet.resource_group" $resource_group
if [ "$vnet_resource_group" = "" ]; then
    vnet_resource_group=$resource_group
fi
az network vnet show \
    --resource-group $vnet_resource_group \
    --name $vnet_name \
    --output table 2>/dev/null
if [ "$?" = "0" ]; then
    status "vnet already exists"
else
    az network vnet create \
        --resource-group $vnet_resource_group \
        --name $vnet_name \
        --address-prefix "$address_prefix" \
        --output table
fi
for subnet_name in $(jq -r ".vnet.subnets | keys | @tsv" $config_file); do
    status "creating subnet $subnet_name"
    read_value subnet_address_prefix ".vnet.subnets.$subnet_name"

    az network vnet subnet show \
        --resource-group $vnet_resource_group \
        --vnet-name $vnet_name \
        --name $subnet_name \
        --output table 2>/dev/null

    if [ "$?" = "0" ]; then
        status "subnet already exists"
    else
        az network vnet subnet create \
            --resource-group $vnet_resource_group \
            --vnet-name $vnet_name \
            --name $subnet_name \
            --address-prefix "$subnet_address_prefix" \
            --output table
    fi
done


for resource_name in $(jq -r ".resources | keys | @tsv" $config_file); do

    read_value resource_type ".resources.$resource_name.type"

    case $resource_type in
        vm)
            status "creating vm: $resource_name"

            az vm show \
                --resource-group $resource_group \
                --name $resource_name \
                --output table 2>/dev/null
            if [ "$?" = "0" ]; then
                status "resource already exists - skipping"
                continue
            fi

            read_value resource_vm_type ".resources.$resource_name.vm_type"
            read_value resource_image ".resources.$resource_name.image"
            read_value resource_pip ".resources.$resource_name.public_ip" false
            read_value resource_subnet ".resources.$resource_name.subnet"
            read_value resource_an ".resources.$resource_name.accelerated_networking" false
            resource_disk_count=$(jq -r ".resources.$resource_name.data_disks | length" $config_file)
            resource_subnet_id="/subscriptions/$subscription_id/resourceGroups/$vnet_resource_group/providers/Microsoft.Network/virtualNetworks/$vnet_name/subnets/$resource_subnet"

            public_ip_address=
            if [ "$resource_pip" = "true" ]; then
                public_ip_address="${resource_name}pip"
            fi

            data_disks_options=
            if [ "$resource_disk_count" -gt 0 ]; then
                data_cache="ReadWrite"
                resource_disk_sizes=$(jq -r ".resources.$resource_name.data_disks | @sh" $config_file)
                for size in $resource_disk_sizes; do
                    if [ $size -gt 4095 ]; then
                        data_cache="None"
                    fi
                done
                data_disks_options="--data-disk-sizes-gb "$resource_disk_sizes" --data-disk-caching $data_cache "
                debug "$data_disks_options"
            fi

            read_value resource_password ".resources.$resource_name.password" "<no-password>"
            if [ "$resource_password" = "<no-password>" ]; then
                resource_credential=(--ssh-key-value "$(<$ssh_public_key)")
            else
                resource_credential=(--admin-password "$resource_password")
            fi

            make_uuid_str

            az vm create \
                --resource-group $resource_group \
                --name $resource_name \
                --image $resource_image \
                --size $resource_vm_type \
                --admin-username $admin_user \
                "${resource_credential[@]}" \
                --storage-sku StandardSSD_LRS \
                --subnet $resource_subnet_id \
                --accelerated-networking $resource_an \
                --public-ip-address "$public_ip_address" \
                --public-ip-address-dns-name $resource_name$uuid_str \
                $data_disks_options \
                --no-wait
        ;;
        vmss)
            status "creating vmss: $resource_name"

            az vmss show \
                --resource-group $resource_group \
                --name $resource_name \
                --output table 2>/dev/null
            if [ "$?" = "0" ]; then
                status "resource already exists - skipping"
                continue
            fi

            read_value resource_vm_type ".resources.$resource_name.vm_type"
            read_value resource_image ".resources.$resource_name.image"
            read_value resource_subnet ".resources.$resource_name.subnet"
            read_value resource_an ".resources.$resource_name.accelerated_networking" false
            read_value resource_instances ".resources.$resource_name.instances"
            resource_subnet_id="/subscriptions/$subscription_id/resourceGroups/$vnet_resource_group/providers/Microsoft.Network/virtualNetworks/$vnet_name/subnets/$resource_subnet"

            read_value resource_password ".resources.$resource_name.password" "<no-password>"
            if [ "$resource_password" = "<no-password>" ]; then
                resource_credential=(--ssh-key-value "$(<$ssh_public_key)")
            else
                resource_credential=(--admin-password "$resource_password")
            fi

            az vmss create \
                --resource-group $resource_group \
                --name $resource_name \
                --image $resource_image \
                --vm-sku $resource_vm_type \
                --admin-username $admin_user \
                "${resource_credential[@]}" \
                --subnet $resource_subnet_id \
                --lb "" \
                --single-placement-group true \
                --accelerated-networking $resource_an \
                --instance-count $resource_instances \
                --no-wait
        ;;
        *)
            error "unknown resource type ($resource_type) for $resource_name"
        ;;
    esac
done

# setup storage while resources are being deployed
for storage_name in $(jq -r ".storage | keys | @tsv" $config_file 2>/dev/null); do

    read_value storage_type ".storage.$storage_name.type"

    case $storage_type in
        anf)
            status "creating anf: $storage_name"

            read_value storage_subnet ".storage.$storage_name.subnet"
            storage_subnet_id="/subscriptions/$subscription_id/resourceGroups/$vnet_resource_group/providers/Microsoft.Network/virtualNetworks/$vnet_name/subnets/$storage_subnet"

            # check if the deletation exists
            delegation_exists=$(\
                az network vnet subnet show \
                    --resource-group $vnet_resource_group \
                    --vnet-name $vnet_name \
                    --name $storage_subnet \
                | jq -r '.delegations[] | select(.serviceName == "Microsoft.Netapp/volumes") | true'
            )

            if [ "$delegation_exists" == "" ]; then
                debug "creating delegation"
                az network vnet subnet update \
                    --resource-group $vnet_resource_group \
                    --vnet-name $vnet_name \
                    --name $storage_subnet \
                    --delegations "Microsoft.Netapp/volumes" \
                    --output table
            fi

            debug "creating netapp account"
            az netappfiles account create \
                --resource-group $resource_group \
                --account-name $storage_name \
                --location $location \
                --output table

            # loop over pools
            for pool_name in $(jq -r ".storage.$storage_name.pools | keys | .[]" $config_file); do
                read_value pool_size ".storage.$storage_name.pools.$pool_name.size"
                read_value pool_service_level ".storage.$storage_name.pools.$pool_name.service_level"

                mount_script="scripts/auto_netappfiles_mount_${pool_name}.sh"
                mkdir -p scripts
                status "Building script: $mount_script"
                echo "#!/bin/bash" > $mount_script
                echo "yum install -y nfs-utils" >> $mount_script

                # create pool
                az netappfiles pool create \
                    --resource-group $resource_group \
                    --account-name $storage_name \
                    --location $location \
                    --service-level $pool_service_level \
                    --size $(($pool_size * (2 ** 40)))\
                    --pool-name $pool_name \
                    --output table

                # loop over volumes
                for volume_name in $(jq -r ".storage.$storage_name.pools.$pool_name.volumes | keys | .[]" $config_file); do
                    read_value volume_size ".storage.$storage_name.pools.$pool_name.volumes.$volume_name.size"

                    az netappfiles volume create \
                        --resource-group $resource_group \
                        --account-name $storage_name \
                        --location $location \
                        --service-level $pool_service_level \
                        --usage-threshold $(($volume_size * (2 ** 40))) \
                        --creation-token ${volume_name} \
                        --pool-name $pool_name \
                        --volume-name $volume_name \
                        --subnet-id $storage_subnet_id \
                        --output table

                    volume_ip=$( \
                        az netappfiles list-mount-targets \
                            --resource-group $resource_group \
                            --account-name $storage_name \
                            --pool-name $pool_name \
                            --volume-name $volume_name \
                            --query [0].ipAddress \
                            --output tsv \
                    )
                    read_value mount_point ".storage.$storage_name.pools.$pool_name.volumes.$volume_name.mount"

                    echo "mkdir $mount_point" >> $mount_script
                    echo "echo \"$volume_ip:/$volume_name	$mount_point	nfs bg,rw,hard,noatime,nolock,rsize=65536,wsize=65536,vers=3,tcp,_netdev 0 0\" >> /etc/fstab" >> $mount_script
                    echo "chmod 777 $mount_point" >> $mount_script
                done
                echo "mount -a" >> $mount_script
                chmod 777 $mount_script

            done
        ;;
        *)
            error "unknown resource type ($storage_type) for $storage_name"
        ;;
    esac
done

# now wait for resources
for resource_name in $(jq -r ".resources | keys | @tsv" $config_file); do
    status "waiting for $resource_name to be created"
    read_value resource_type ".resources.$resource_name.type"
    az $resource_type wait \
        --resource-group $resource_group \
        --name $resource_name \
        --created \
        --output table
done

# setting up a route
for route_name in $(jq -r ".vnet.routes | keys | @tsv" $config_file 2>/dev/null); do
    status "creating $route_name route table"

    az network route-table show \
        --resource-group $vnet_resource_group \
        --name $route_name \
        --output table 2>/dev/null
    if [ "$?" = "0" ]; then
        status "route table exists - skipping"
    fi

    read_value route_address_prefix ".vnet.routes.$route_name.address_prefix"
    read_value route_next_hop_vm ".vnet.routes.$route_name.next_hop"
    read_value route_subnet ".vnet.routes.$route_name.subnet"

    route_next_hop=$(\
        az vm show \
            --resource-group $resource_group \
            --name $route_next_hop_vm \
            --show-details \
            --query privateIps \
            --output tsv \
    )

    az network route-table create \
        --resource-group $vnet_resource_group \
        --name $route_name \
        --output table
    az network route-table route create \
        --resource-group $vnet_resource_group \
        --address-prefix $route_address_prefix \
        --next-hop-type VirtualAppliance \
        --route-table-name $route_name \
        --next-hop-ip-address $route_next_hop \
        --name $route_name \
        --output table
    az network vnet subnet update \
        --vnet-name $vnet_name \
        --name $route_subnet \
        --resource-group $vnet_resource_group \
        --route-table $route_name \
        --output table

done


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

status "building hostlists"
rm -rf $tmp_dir/hostlists
mkdir -p $tmp_dir/hostlists/tags
for resource_name in $(jq -r ".resources | keys | @tsv" $config_file); do

    read_value resource_type ".resources.$resource_name.type"

    if [ "$resource_type" = "vmss" ]; then

        az vmss list-instances \
            --resource-group $resource_group \
            --name $resource_name \
            --query [].osProfile.computerName \
            --output tsv \
            > $tmp_dir/hostlists/$resource_name

        for tag in $(jq -r ".resources.$resource_name.tags | @tsv" $config_file); do
            cat $tmp_dir/hostlists/$resource_name >> $tmp_dir/hostlists/tags/$tag
        done

        cat $tmp_dir/hostlists/$resource_name >> $tmp_dir/hostlists/global

    elif [ "$resource_type" = "vm" ]; then
        # only get ip for passwordless nodes
        read_value resource_password ".resources.$resource_name.password" "<no-password>"
        if [ "$resource_password" = "<no-password>" ]; then
            resource_credential=(--ssh-key-value "$(<$ssh_public_key)")

            az vm show \
                --resource-group $resource_group \
                --name $resource_name \
                --query osProfile.computerName \
                --output tsv \
                > $tmp_dir/hostlists/$resource_name

            for tag in $(jq -r ".resources.$resource_name.tags | @tsv" $config_file); do
                cat $tmp_dir/hostlists/$resource_name >> $tmp_dir/hostlists/tags/$tag
            done

            cat $tmp_dir/hostlists/$resource_name >> $tmp_dir/hostlists/global
        fi
    fi

done

nsteps=$(jq -r ".install | length" $config_file)

if [ "$nsteps" -eq 0 ]; then

    status "no install steps"

else

    status "building install scripts - $nsteps steps"
    install_sh=$tmp_dir/install.sh

    cat <<OUTER_EOF > $install_sh
#!/bin/bash

cd ~/$tmp_dir

sudo yum install -y epel-release > step_0_install_node_setup.log 2>&1
sudo yum install -y pssh nc >> step_0_install_node_setup.log 2>&1

# setting up keys
cat <<EOF > ~/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF
cp $ssh_public_key ~/.ssh/id_rsa.pub
cp $ssh_private_key ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/config
chmod 644 ~/.ssh/id_rsa.pub

prsync -p $pssh_parallelism -a -h hostlists/global ~/$tmp_dir ~ >> step_0_install_node_setup.log 2>&1
prsync -p $pssh_parallelism -a -h hostlists/global ~/.ssh ~ >> step_0_install_node_setup.log 2>&1

pssh -p $pssh_parallelism -t 0 -i -h hostlists/global 'echo "AcceptEnv PSSH_NODENUM PSSH_HOST" | sudo tee -a /etc/ssh/sshd_config' >> step_0_install_node_setup.log 2>&1
pssh -p $pssh_parallelism -t 0 -i -h hostlists/global 'sudo systemctl restart sshd' >> step_0_install_node_setup.log 2>&1
pssh -p $pssh_parallelism -t 0 -i -h hostlists/global "echo 'Defaults env_keep += \"PSSH_NODENUM PSSH_HOST\"' | sudo tee -a /etc/sudoers" >> step_0_install_node_setup.log 2>&1
OUTER_EOF

    for step in $(seq 1 $nsteps); do
        idx=$(($step - 1))

        read_value install_script ".install[$idx].script"
        read_value install_tag ".install[$idx].tag"
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
                echo "pscp.pssh -p $pssh_parallelism -h hostlists/tags/$install_tag $f \$(pwd) >> step_${step}_${install_script%.sh}.log 2>&1" >>$install_sh
            done
        fi

        sudo_prefix=
        if [ "$install_sudo" = "true" ]; then
            sudo_prefix=sudo
        fi

        # can run in parallel with pssh
        echo "pssh -p $pssh_parallelism -t 0 -i -h hostlists/tags/$install_tag \"cd $tmp_dir; $sudo_prefix scripts/$install_command_line\" >> step_${step}_${install_script%.sh}.log 2>&1" >>$install_sh

        if [ "$install_reboot" = "true" ]; then
            cat <<EOF >> $install_sh
pssh -p $pssh_parallelism -t 0 -i -h hostlists/tags/$install_tag "sudo reboot" >> step_${step}_${install_script%.sh}.log 2>&1
echo "    Waiting for nodes to come back"
sleep 10
for h in \$(<hostlists/tags/$install_tag); do
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

# run a post install script if there is one
read_value post_install_script ".post_install.script" "<no-post-install>"
if [ "$post_install_script" != "<no-post-install>" ]; then
    status "running the post install script"
    post_install_args=()
    post_install_arg_count=$(jq -r ".post_install.args | length" $config_file)
    if [ "$post_install_arg_count" -ne "0" ]; then
        for n in $(seq 0 $((post_install_arg_count - 1))); do
            read_value arg ".post_install.args[$n]"
            post_install_args+=($arg)
        done
    fi

    ./$post_install_script "${post_install_args[@]}"
fi

status "cluster ready"

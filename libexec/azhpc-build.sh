#!/bin/bash
export azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$azhpc_dir/libexec/common.sh"
source "$azhpc_dir/libexec/install_helper.sh"

DEBUG_ON=0
COLOR_ON=1
config_file="config.json"

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

az_version=$(az --version | grep ^azure-cli | awk '{print $2}')
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

if version_gt "2.0.73" "$az_version"; then
    warning "az version may be too low for some functionality: $az_version"
fi   

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
read_value ppg_name ".proximity_placement_group_name" null

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
    --output table || exit 1

if [ "$ppg_name" != null ]; then
   status "creating proximity placement group"
   az ppg show -n $ppg_name -g $resource_group --output table 2>/dev/null
   if [ "$?" = "0" ]; then
      status "proximity placement group already exists"
   else
      az ppg create -n $ppg_name -g $resource_group -l $location -t standard --output table
   fi
fi

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
        --output table || exit 1
fi

read_value vnet_dns_domain ".vnet.dns_domain" null
if [ $vnet_dns_domain != null ]; then
  status "creating private dns"
  az network private-dns zone show \
      --resource-group $resource_group \
      --name $vnet_dns_domain \
      --output table 2>/dev/null
  if [ "$?" = "0" ]; then
      status "private dns already exists"
  else
  az network private-dns zone create \
      --resource-group $resource_group \
      --name $vnet_dns_domain \
      --output table || exit 1
  fi
  status "creating vnet link to private dns"
  az network private-dns link vnet show \
      --resource-group $resource_group \
      --name $vnet_name \
      --zone-name $vnet_dns_domain \
      --output table 2>/dev/null
  if [ "$?" = "0" ]; then
      status "vnet link to private dns already exists"
  else
  az network private-dns link vnet create \
      --resource-group $resource_group \
      --name $vnet_name \
      --zone-name $vnet_dns_domain \
      --virtual-network $vnet_name \
      --registration-enabled true \
      --output table || exit 1
  fi
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
            --output table || exit 1
    fi
    
    read_value peer_exists ".vnet.peer" "None"
    if [ "$peer_exists" = "None" ]; then
        continue
    fi
    for peer_name in $(jq -r ".vnet.peer | keys | @tsv" $config_file); do
	status "setting up network peering for $peer_name"
	read_value peer_vnet_name ".vnet.peer.$peer_name.vnet_name"
	read_value peer_vnet_resource_group ".vnet.peer.$peer_name.resource_group"

	echo "Name: $peer_vnet_name, RG: $peer_vnet_resource_group"
	if [[ "$peer_vnet_name" = "" ]] || [[ "$peer_vnet_resource_group" = "" ]]
	then
	    echo "One or more of the variables are not correctly"
	    echo "Name: $peer_vnet_name, RG: $peer_vnet_resource_group"
	    continue
	fi

	# Get vnet ids
	id_1=`az network vnet list -g $vnet_resource_group --query [].id --output tsv | grep $vnet_name`
	id_2=`az network vnet list -g $peer_vnet_resource_group --query [].id --output tsv | grep $peer_vnet_name`

	status "Checking if rg-${vnet_resource_group}-${vnet_name}-2-${peer_vnet_name} for $vnet_name already exists"
	az network vnet peering show \
	    -g $vnet_resource_group \
	    -n rg-${vnet_resource_group}-${vnet_name}-2-${peer_vnet_name} \
	    --vnet-name $vnet_name \

	if [ "$?" = "0" ]; then
	    status "rg-${vnet_resource_group}-${vnet_name}-2-${peer_vnet_name} already exists"
	else
	    status "Creating vnet peer rg-${vnet_resource_group}-${vnet_name}-2-${peer_vnet_name} for $vnet_name"
	    az network vnet peering create \
		-g $vnet_resource_group \
		-n rg-${vnet_resource_group}-${vnet_name}-2-${peer_vnet_name} \
		--vnet-name $vnet_name \
		--remote-vnet $id_2 \
		--allow-forwarded-traffic \
		--allow-vnet-access || exit 1
	fi

	status "Checking if rg-${vnet_resource_group}-${vnet_name}-2-${peer_vnet_name} for $peer_vnet_name already exists"
	az network vnet peering show \
	    -g $peer_vnet_resource_group \
	    -n rg-${vnet_resource_group}-${vnet_name}-2-${peer_vnet_name} \
	    --vnet-name $peer_vnet_name \

	if [ "$?" = "0" ]; then
	    status "rg-${vnet_resource_group}-${vnet_name}-2-${peer_vnet_name} already exists"
	else
	    status "Creating vnet peer rg-${vnet_resource_group}-${vnet_name}-2-${peer_vnet_name} for $peer_vnet_name"
	    az network vnet peering create \
		-g $peer_vnet_resource_group \
		-n rg-${vnet_resource_group}-${vnet_name}-2-${peer_vnet_name} \
		--vnet-name $peer_vnet_name \
		--remote-vnet $id_1 \
		--allow-forwarded-traffic \
		--allow-vnet-access || exit 1
	fi
    done
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
            read_value resource_ppg ".resources.$resource_name.proximity_placement_group" false
            read_value resource_subnet ".resources.$resource_name.subnet"
            read_value resource_an ".resources.$resource_name.accelerated_networking" false
            resource_disk_count=$(jq -r ".resources.$resource_name.data_disks | length" $config_file)
            resource_subnet_id="/subscriptions/$subscription_id/resourceGroups/$vnet_resource_group/providers/Microsoft.Network/virtualNetworks/$vnet_name/subnets/$resource_subnet"

            public_ip_address=
            if [ "$resource_pip" = "true" ]; then
                public_ip_address="${resource_name}pip"
            fi
            ppg_option=
            if [ "$resource_ppg" = "true" ]; then
               if [ "$ppg_name" != null ]; then
                   ppg_option="--ppg $ppg_name"
               else
                   error "Failed: ppg_name needs to be defined to use proximity placement group"
               fi
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
                $ppg_option \
                --no-wait || exit 1
            
            if [ "$?" -ne "0" ]; then
                error "Failed to create resource"
            fi
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
            read_value resource_fault_domain_count ".resources.$resource_name.fault_domain_count" 5
            read_value resource_an ".resources.$resource_name.accelerated_networking" false
            read_value resource_lowpri ".resources.$resource_name.low_priority" false
            read_value resource_ppg ".resources.$resource_name.proximity_placement_group" false
            read_value resource_instances ".resources.$resource_name.instances"
            resource_disk_count=$(jq -r ".resources.$resource_name.data_disks | length" $config_file)
            resource_subnet_id="/subscriptions/$subscription_id/resourceGroups/$vnet_resource_group/providers/Microsoft.Network/virtualNetworks/$vnet_name/subnets/$resource_subnet"


            resource_storage_sku=StandardSSD_LRS
            data_disks_options=
            if [ "$resource_disk_count" -gt 0 ]; then
                read_value resource_storage_sku ".resources.$resource_name.storage_sku"
                data_cache="ReadWrite"
                resource_disk_sizes=$(jq -r ".resources.$resource_name.data_disks | @sh" $config_file)
                for size in $resource_disk_sizes; do
                    if [ $size -gt 4095 ] || [[ $resource_vm_type ==  Standard_L*s_v2 ]]; then
                        data_cache="None"
                    fi
                done
                data_disks_options="--storage-sku $resource_storage_sku --data-disk-sizes-gb "$resource_disk_sizes" --data-disk-caching $data_cache "
                debug "$data_disks_options"
            fi

            read_value resource_password ".resources.$resource_name.password" "<no-password>"
            if [ "$resource_password" = "<no-password>" ]; then
                resource_credential=(--ssh-key-value "$(<$ssh_public_key)")
            else
                resource_credential=(--admin-password "$resource_password")
            fi
            lowpri_option=
            if [ "$resource_lowpri" = "true" ]; then
                lowpri_option="--priority Low"
            fi
            ppg_option=
            if [ "$resource_ppg" = "true" ]; then
               if [ "$ppg_name" != null ]; then
                   ppg_option="--ppg $ppg_name"
               else
                   error "Failed: ppg_name needs to be defined to use proximity placement group"
               fi
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
                --platform-fault-domain-count  $resource_fault_domain_count \
                --accelerated-networking $resource_an \
                --instance-count $resource_instances \
                $data_disks_options \
                $lowpri_option \
                $ppg_option \
                --no-wait || exit 1
            
            if [ "$?" -ne "0" ]; then
                error "Failed to create resource"
            fi
        ;;
        *)
            error "unknown resource type ($resource_type) for $resource_name"
        ;;
    esac
done

# setup storage while resources are being deployed
for storage_name in $(jq -r ".storage | keys | @tsv" $config_file 2>/dev/null); do
    status "Storage Name: $storage_name"
    read_value storage_type ".storage.\"$storage_name\".type"
    status "Storage Type: $storage_type"
    read_value storage_resource_group ".storage.\"$storage_name\".resource_group" $resource_group
    status "Storage RG: $storage_resource_group"

    case $storage_type in
        anf)
            status "creating anf: $storage_name"

            read_value storage_subnet ".storage.\"$storage_name\".subnet"
            storage_vnet_id="/subscriptions/$subscription_id/resourceGroups/$vnet_resource_group/providers/Microsoft.Network/virtualNetworks/$vnet_name"

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
                    --output table || exit 1
            fi

            debug "creating netapp account"
            az netappfiles account show \
                --resource-group $storage_resource_group \
                --name $storage_name \
                --output table 2>/dev/null
            if [ "$?" = "0" ]; then
                status "account $storage_name already exists"
            else
                az netappfiles account create \
                    --resource-group $storage_resource_group \
                    --account-name $storage_name \
                    --location $location \
                    --output table || exit 1
	    fi

	    read_value storage_anf_domain ".storage.\"$storage_name\".joindomain" "None"
            if [ ! "$storage_anf_domain" = "None" ]; then
                debug "netapp account joining domain"
	        read_value storage_anf_domain_ad ".storage.\"$storage_name\".ad_server"
	        read_value storage_anf_domain_password ".storage.\"$storage_name\".ad_password"
	        read_value storage_anf_domain_admin ".storage.\"$storage_name\".ad_admin"
	        ad_dns=$(az vm list-ip-addresses -g $storage_resource_group -n $storage_anf_domain_ad --query [0].virtualMachine.network.privateIpAddresses --output tsv)
                az netappfiles account ad add \
                    --dns $ad_dns \
                    --domain $storage_anf_domain \
                    --password $storage_anf_domain_password \
                    --smb-server-name anf \
                    --username $storage_anf_domain_admin \
                    --resource-group $storage_resource_group \
                    --name $storage_name || exit 1
            fi

            # loop over pools
            mount_script="scripts/auto_netappfiles_mount.sh"
            mkdir -p scripts
            status "Building script: $mount_script"
            echo "#!/bin/bash" > $mount_script
            echo "yum install -y nfs-utils" >> $mount_script
            for pool_name in $(jq -r ".storage.\"$storage_name\".pools | keys | .[]" $config_file); do
                read_value pool_size ".storage.\"$storage_name\".pools.\"$pool_name\".size"
                read_value pool_service_level ".storage.\"$storage_name\".pools.\"$pool_name\".service_level"

                mount_script="scripts/auto_netappfiles_mount.sh"
                mkdir -p scripts
                status "Building script: $mount_script"
                echo "#!/bin/bash" > $mount_script
                echo "yum install -y nfs-utils cifs-utils" >> $mount_script

                # create pool
                status "Resource Group: $storage_resource_group"
                status "Account Name: $storage_name"
                status "Pool Name: $pool_name"
                az netappfiles pool show \
                    --resource-group $storage_resource_group \
                    --account-name $storage_name \
                    --name $pool_name \
                    --output table 2>/dev/null
                if [ "$?" = "0" ]; then
                    status "pool $pool_name already exists"
                else
                    # pool_size is in TiB
                    status "create pool: $pool_name"
                    az netappfiles pool create \
                        --resource-group $storage_resource_group \
                        --account-name $storage_name \
                        --location $location \
                        --service-level $pool_service_level \
                        --size $pool_size \
                        --pool-name $pool_name \
                        --output table || exit 1
                fi
                # loop over volumes
                for volume_name in $(jq -r ".storage.\"$storage_name\".pools.\"$pool_name\".volumes | keys | .[]" $config_file); do
                    read_value volume_size ".storage.\"$storage_name\".pools.\"$pool_name\".volumes.\"$volume_name\".size"
                    read_value export_type ".storage.\"$storage_name\".pools.\"$pool_name\".volumes.\"$volume_name\".type" nfs

		    if [ "$export_type" == "cifs" ]; then 
		      echo prepping for cifs
                      az netappfiles volume create \
                          --resource-group $storage_resource_group \
                          --account-name $storage_name \
                          --location $location \
                          --service-level $pool_service_level \
                          --usage-threshold $(($volume_size * (2 ** 10))) \
                          --file-path ${volume_name} \
                          --pool-name $pool_name \
                          --volume-name $volume_name \
			  --protocol-type CIFS \
 			  --vnet $vnet_name \
                          --subnet $storage_subnet \
                          --output table || exit 1

                      volume_ip=$( \
                          az netappfiles list-mount-targets \
                            --resource-group $storage_resource_group \
                            --account-name $storage_name \
                            --pool-name $pool_name \
                            --volume-name $volume_name \
                            --query [0].ipAddress \
                            --output tsv || exit 1
                      )
                      read_value mount_point ".storage.\"$storage_name\".pools.\"$pool_name\".volumes.\"$volume_name\".mount"
                      echo "mkdir -p $mount_point" >> $mount_script
                      echo "echo '\\\\$volume_ip\\$volume_name	$mount_point 	cifs	_netdev,username=$storage_anf_domain_admin,password=$storage_anf_domain_password,dir_mode=0755,file_mode=0755,uid=500,gid=500 0 0' >> /etc/fstab" >> $mount_script
                      echo "chmod 777 $mount_point" >> $mount_script

		    else
                        # volume_size should be in GiB
                        az netappfiles volume show \
                            --resource-group $storage_resource_group \
                            --account-name $storage_name \
                            --pool-name $pool_name \
                            --name $volume_name \
                            --output table 2>/dev/null
                        if [ "$?" = "0" ]; then
                           status "volume $volume_name already exists"
                        else
                            status "create volume: $volume_name"
                            az netappfiles volume create \
                                --resource-group $storage_resource_group \
                                --account-name $storage_name \
                                --location $location \
                                --service-level $pool_service_level \
                                --usage-threshold $(($volume_size * (2 ** 10))) \
                                --file-path ${volume_name} \
                                --pool-name $pool_name \
                                --volume-name $volume_name \
                                --vnet $vnet_name \
                                --subnet $storage_subnet \
                                --output table || exit 1
                        fi
                        volume_ip=$( \
                            az netappfiles list-mount-targets \
                                --resource-group $storage_resource_group \
                                --account-name $storage_name \
                                --pool-name $pool_name \
                                --volume-name $volume_name \
                                --query [0].ipAddress \
                                --output tsv || exit 1
                        )
                        # if we have private-dns: register ip-addres for ANF
                        if [ $vnet_dns_domain != null ]; then
                          aRecord=$( \
                            az network private-dns record-set a show \
                              --resource-group $resource_group \
                              --zone-name $vnet_dns_domain \
                              --name ${storage_name}-${volume_name} \
                              --query [aRecords] 2>/dev/null | jq -r '.[][].ipv4Address') 
                          if [ ${aRecord}x == ${volume_ip}x ]; then
                            status "entry in dns for ${storage_name}-${volume_name} already exists"
                          else   
                            status "create entry in ${vnet_dns_domain} dns for ${storage_name}-${volume_name}"
                            az network private-dns record-set a add-record \
                              --resource-group $resource_group \
                              --zone-name $vnet_dns_domain \
                              --record-set-name ${storage_name}-${volume_name} \
                              --ipv4-address $volume_ip \
                              --output table || exit 1
                          fi
                        fi

                        read_value mount_point ".storage.\"$storage_name\".pools.\"$pool_name\".volumes.\"$volume_name\".mount"
                        echo "mkdir -p $mount_point" >> $mount_script
                        echo "grep -v '\s${mount_point}' /etc/fstab > /etc/fstab.bak" >> $mount_script
                        echo "echo \"$volume_ip:/$volume_name  $mount_point  nfs bg,rw,hard,noatime,nolock,rsize=65536,wsize=65536,vers=3,tcp,_netdev 0 0\" >> /etc/fstab.bak" >> $mount_script
                        echo "mv /etc/fstab.bak /etc/fstab" >> $mount_script
                        echo "chmod 777 $mount_point" >> $mount_script
		    fi
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
        --output table || exit 1
    az network route-table route create \
        --resource-group $vnet_resource_group \
        --address-prefix $route_address_prefix \
        --next-hop-type VirtualAppliance \
        --route-table-name $route_name \
        --next-hop-ip-address $route_next_hop \
        --name $route_name \
        --output table || exit 1
    az network vnet subnet update \
        --vnet-name $vnet_name \
        --name $route_subnet \
        --resource-group $vnet_resource_group \
        --route-table $route_name \
        --output table || exit 1

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
build_hostlists "$config_file" "$tmp_dir"

status "building install scripts"
create_install_scripts \
    "$config_file" \
    "$tmp_dir" \
    "$ssh_public_key" \
    "$ssh_private_key" \
    "$SSH_ARGS" \
    "$admin_user" \
    "$local_script_dir" \
    "$fqdn"

status "running the install scripts"
run_install_scripts \
    "$config_file" \
    "$tmp_dir" \
    "$ssh_private_key" \
    "$SSH_ARGS" \
    "$admin_user" \
    "$local_script_dir" \
    "$fqdn"

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

    $tmp_dir/scripts/$post_install_script "${post_install_args[@]}"
fi

status "cluster ready"

#!/bin/bash
export azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$azhpc_dir/libexec/common.sh"
source "$azhpc_dir/libexec/install_helper.sh"

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

status "building hostlists"
build_hostlists "$config_file" "$tmp_dir"
cp $tmp_dir/$vmss_resource-hosts-added $tmp_dir/hostlists/tags/$vmss_resource.added

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
    "$fqdn" \
    "$vmss_resource"

status "cluster ready"

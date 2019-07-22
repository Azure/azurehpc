#!/bin/bash
azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$azhpc_dir/libexec/common.sh"

config_file="config.json"

DEBUG_ON=0
COLOR_ON=1

function usage() {
    echo "Command:"
    echo "    $0 [options] resource"
    echo
    echo "Arguments"
    echo "    -h --help       : diplay this help"
    echo "    -c --config FILE: config file to use"
    echo "                      default: config.json"
    echo "    -u --user USER  : switch user"
    echo "                      default: <admin-user>"
    echo
}

ssh_user=

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
        -u|--user)
        ssh_user="$2"
        shift
        shift
        ;;
        *)
        break
    esac
done

resource_name=$1
shift

if [ "$resource_name" = "" ]; then
    error "No resource specified"
fi

read_value location ".location"
read_value resource_group ".resource_group"
read_value vnet_name ".vnet.name"
read_value address_prefix ".vnet.address_prefix"
read_value admin_user ".admin_user"
read_value install_node ".install_from"

ssh_private_key=${admin_user}_id_rsa
if [ ! -e "$ssh_private_key" ]; then
    error "keys not found"
fi

if [ "$ssh_user" = "" ]; then
    ssh_user=$admin_user
fi

fqdn=$(
    az network public-ip show \
        --resource-group $resource_group \
        --name ${install_node}pip --query dnsSettings.fqdn \
        --output tsv \
)

if [ "$fqdn" = "" ]; then
    status "The install node does not have a public IP.  Using hostname - $install_node - and must be on this node must be on the same vnet"
fi

read_value resource_type ".resources.$resource_name.type" "<not-a-resource>"

target=
if [ "$resource_type" = "vm" ]; then
    target=$(az vm show \
        --resource-group $resource_group \
        --name $resource_name \
        --query osProfile.computerName \
        --output tsv | head -n1)

elif [ "$resource_type" = "vmss" ]; then
    debug "choosing first node in $resource_name vmss"
    target=$(az vmss list-instances \
        --resource-group $resource_group \
        --name $resource_name \
        --query [].osProfile.computerName \
        --output tsv | head -n1)

else
    target=$resource_name
    debug "trying to log in to $target from $install_node"
    #error "unknown resource type ($resource_type) for $resource_name"
fi

status "logging in to $target (via $fqdn)"

command=

if [ "$#" -gt "0" ]; then
    command="/bin/bash -c '$@'"
fi

if [ "$resource_name" = "$install_node" ]; then
    exec ssh -t -q $SSH_ARGS -i $ssh_private_key $ssh_user@$fqdn "$command"
else
    exec ssh -t -q $SSH_ARGS -i $ssh_private_key $ssh_user@$fqdn "ssh -t -q $target \"$command\""
fi

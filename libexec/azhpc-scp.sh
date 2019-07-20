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

exec scp -q $SSH_ARGS -i $ssh_private_key -o ProxyCommand="ssh -q $SSH_ARGS -i $ssh_private_key -W %h:%p $ssh_user@$fqdn" "$@"

#!/bin/bash
azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$azhpc_dir/libexec/common.sh"

DEBUG_ON=0
COLOR_ON=1

function usage() {
    echo "Command:"
    echo "    $0 [options] <command>"
    echo
    echo "Arguments"
    echo "    -h --help       : diplay this help"
    echo "    -c --config FILE: config file to use"
    echo "                      default: config.json"
    echo "    -u --user USER  : switch user"
    echo "                      default: <admin-user>"
    echo "    -n --nodes NODES: list of nodes, space separated"
    echo "                      can be resources or hostnames"
    echo "                      default: <install_from>"
    echo
}

config_file="config.json"
ssh_user=
hosts=()

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
        -n|--nodes)
        hosts=($(echo "$2" | tr ' ' '\n'))
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

if [ "$ssh_user" = "" ]; then
    ssh_user=$admin_user
fi
if [ "${#hosts}" -eq "0" ]; then
    hosts=($install_node)
fi

ssh_private_key=${admin_user}_id_rsa
ssh_public_key=${admin_user}_id_rsa.pub
if [ ! -e "$ssh_private_key" ]; then
    error "keys not found"
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

hostnames=()

for resource_name in "${hosts[@]}"; do
    read_value resource_type ".resources.$resource_name.type" "<unknown>"

    if [ "$resource_type" = "vm" ]; then
        hostnames+=($(az vm show \
            --resource-group $resource_group \
            --name $resource_name \
            --query osProfile.computerName \
            --output tsv))

    elif [ "$resource_type" = "vmss" ]; then
        hostnames+=($(az vmss list-instances \
            --resource-group $resource_group \
            --name $resource_name \
            --query [].osProfile.computerName \
            --output tsv))

    else
        hostnames+=($resource_name)
    fi

done

ssh $SSH_ARGS -q -i $ssh_private_key $ssh_user@$fqdn "pssh -H \"${hostnames[@]}\" -i -t 0'$@'"

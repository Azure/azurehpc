#!/bin/bash

if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "Error: this script should be sourced and not executed"
    exit 1
fi

SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q"

function debug()
{
    if [ "$DEBUG_ON" -eq "1" ]; then
        if [ "$COLOR_ON" -ne "1" ]; then
            echo "$(date) : $1"
        else
            echo -e "\e[37m$(date) debug : \e[1m$1\e[0m"
        fi
    fi
}

function status()
{
    if [ "$COLOR_ON" -ne "1" ]; then
        echo "$(date) : $1"
    else
        echo -e "\e[32m$(date) : \e[1m$1\e[0m"
    fi
}

function warning()
{
    if [ "$COLOR_ON" -ne "1" ]; then
        echo "$(date) : $1"
    else
        echo -e "\e[33m$(date) warning : \e[1m$1\e[0m"
    fi
}

function error()
{
    if [ "$COLOR_ON" -ne "1" ]; then
        echo "$(date) : Error $1"
    else
        echo -e "\e[31m$(date) error : \e[1m$1\e[0m"
    fi
    exit 1
}

function make_uuid_str {
    uuid_str=""
    if which uuidgen >/dev/null; then
        uuid_str="$(uuidgen | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
    else
        uuid_str="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
    fi
}

# read a read_subvalue. if formatted with brakets like [subvalue], then the subvalue is used as a new value to read from the config file
# syntax read_subvalue <variable> <value>
function read_subvalue {
    value=$2
    firstletter=${value:0:1}
    if [ "$firstletter" == "[" ]; then
        value=$(echo $value | awk -F'[][]' '{print $2}')
        read_value $value ".${!value}"
    fi
    read $1 <<< $value
}


function read_value {
    read $1 <<< $(jq -r "$2" $config_file)
    if [ "${!1}" = "null" ]; then
        if [ -z "$3" ]; then
            error "failed to read $2 from $config_file"
        else
            read $1 <<< $3
            debug "read_value: $1=${!1} (default)"
        fi
    else
        debug "read_value: $1=${!1}"
    fi

    prefix=${!1%%.*}
    if [ "$prefix" = "variables" ]; then
        read_value $1 ".${!1}"
    elif [ "$prefix" = "secret" ]; then
        keyvault_str=${!1#*.}
        vault_name=${keyvault_str%.*}
        read_subvalue vault_name $vault_name
        key_name=${keyvault_str#*.}
        read_subvalue key_name $key_name
        debug "read_value reading from keyvault (keyvault=$vault_name, key=$key_name)"
        read $1 <<< $(az keyvault secret show --name $key_name --vault-name $vault_name -o json | jq -r '.value')

    elif [ "$prefix" = "sasurl" ]; then
        sasurl_storage_str=${!1#*.}
        sasurl_storage_account=${sasurl_storage_str%%.*}
        sasurl_storage_fullpath=${sasurl_storage_str#*.}
        sasurl_storage_container=${sasurl_storage_fullpath%%/*}
        sasurl_storage_url="$( \
            az storage account show \
                --name $sasurl_storage_account \
                --query primaryEndpoints.blob \
                --output tsv \
        )"
        sasurl_storage_saskey=$( \
            az storage container generate-sas \
            --account-name $sasurl_storage_account \
            --name $sasurl_storage_container \
            --permissions r \
            --start $(date --utc -d "-2 hours" +%Y-%m-%dT%H:%M:%SZ) \
            --expiry $(date --utc -d "+1 hour" +%Y-%m-%dT%H:%M:%SZ) \
            --output tsv
        )
        sasurl_storage_full="$sasurl_storage_url$sasurl_storage_fullpath?$sasurl_storage_saskey"
        debug "read_value creating a sasurl (account=$sasurl_storage_account,  fullpath=$sasurl_storage_fullpath, container=$sasurl_storage_container, sasurl=$sasurl_storage_full"
        read $1 <<< "$sasurl_storage_full"

    elif [ "$prefix" = "fqdn" ]; then
        fqdn_str=${!1#*.}
        resource_name=${fqdn_str%.*}
        debug "getting FQDN for $resource_name in $resource_group"
        fqdn=$(
            az network public-ip show \
                --resource-group $resource_group \
                --name ${resource_name}pip --query dnsSettings.fqdn \
                --output tsv \
                2>/dev/null \
        )
        read $1 <<< "$fqdn"

    elif [ "$prefix" = "sakey" ]; then
        sakey_str=${!1#*.}
        storage_name=${sakey_str%.*}
        read_subvalue storage_name $storage_name
        debug "getting storage key for $storage_name in $resource_group"
        storage_key=$(az storage account keys list -g $resource_group -n $storage_name --query "[0].value" | sed 's/\"//g')
        read $1 <<< "$storage_key"

    fi

}

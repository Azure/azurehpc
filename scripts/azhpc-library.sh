#!/bin/bash
# Library of functions to be used across scripts

is_centos8()
{
    read_os
    if [ "$os_release" == "centos" ] && [ "$os_maj_ver" == "8" ]; then
        return 0
    else
        return 1
    fi
}

is_centos7()
{
    read_os
    if [ "$os_release" == "centos" ] && [ "$os_maj_ver" == "7" ]; then
        return 0 
    else
        return 1
    fi
}

read_os()
{
    os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
    os_maj_ver=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
    full_version=$(cat /etc/$os_release-release | cut -d' ' -f4)
}

function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=5
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

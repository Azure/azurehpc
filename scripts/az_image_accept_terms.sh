#!/bin/bash
set -e
# Accept the licence term of a Markeplace image
image_urn=$1

accepted=$(az vm image terms show --urn $image_urn | jq '.accepted' | tr '[:upper:]' '[:lower:]')

if [ "$accepted" != "true" ]; then
    echo "Accepting terms for $image_urn"
    az vm image terms accept --urn $image_urn
else
    echo "Terms for image $image_urn have already been accepted"
fi


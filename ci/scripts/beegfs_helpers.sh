#!/bin/bash
function get_oss_count()
{
    local mount=${1-/beegfs}
    echo $(beegfs-ctl --listnodes --nodetype=storage --mount=$mount | wc -l)
}

function get_mdt_count()
{
    local mount=${1-/beegfs}
    echo $(beegfs-ctl --listnodes --nodetype=metadata --mount=$mount | wc -l)
}

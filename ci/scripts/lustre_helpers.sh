#!/bin/bash
function get_ost_count()
{
    local mount=${1-/lustre}
    echo $(lfs df $mount | grep OST | wc -l)
}
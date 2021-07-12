#!/bin/bash
yum -y groupinstall --skip-broken "Infiniband Support" 2>/dev/null
echo "done installing Infiniband"
exit 0

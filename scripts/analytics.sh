#!/bin/bash
workspace=$1
key="$2"

cat <<EOF >/etc/profile.d/analytics.sh
export ANALYTICS_WORKSPACE=$workspace
export ANALYTICS_KEY="$key"
EOF

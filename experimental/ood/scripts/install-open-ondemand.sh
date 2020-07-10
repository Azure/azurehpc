#!/bin/bash

username=$1
password=$2

yum -y install centos-release-scl
yum -y install https://yum.osc.edu/ondemand/1.7/ondemand-release-web-1.7-1.noarch.rpm
yum -y install ondemand

iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables-save > /etc/sysconfig/iptables

systemctl start httpd24-httpd

scl enable ondemand -- htpasswd -b -c /opt/rh/httpd24/root/etc/httpd/.htpasswd $username $password

mkdir -p /etc/ood/config/clusters.d

cat <<EOF >/etc/ood/config/clusters.d/pbscluster.yml
v2:
  metadata:
    title: "PBS Cluster"
  login:
    host: "headnode"
  job:
    adapter: "pbspro"
    host: "headnode"
    exec: "/opt/pbs"
  batch_connect:
    basic:
      script_wrapper: |
        module purge
        %s
    vnc:
      script_wrapper: |
        module purge
        export PATH="/opt/TurboVNC/bin:$PATH"
        export WEBSOCKIFY_CMD="/usr/bin/websockify"
        %s
EOF

# reverse proxy (https://osc.github.io/ood-documentation/release-1.7/app-development/interactive/setup/enable-reverse-proxy.html)
cat <<EOF >>/etc/ood/config/ood_portal.yml

host_regex: '[^./]+'
node_uri: '/node'
rnode_uri: '/rnode'
EOF
sudo /opt/ood/ood-portal-generator/sbin/update_ood_portal

# submit desktop session
mkdir -p /etc/ood/config/apps/bc_desktop
cat <<EOF >/etc/ood/config/apps/bc_desktop/pbscluster.yml 
---
title: "PBS Cluster"
cluster: "pbscluster"
form:
  - desktop
  - bc_num_hours
attributes:
  bc_num_hours:
    value: 1
  bc_job_name:
    value: "test"
  desktop: "xfce"
submit: "submit/my_submit.yml.erb"
EOF
# custom script
mkdir -p /etc/ood/config/apps/bc_desktop/submit
cat <<EOF >/etc/ood/config/apps/bc_desktop/submit/my_submit.yml.erb
---
script:
  native:
    - "-l"
    - "select=1:ncpus=30"
EOF

# change the branding
# and fix the qsub issue (https://osc.github.io/ood-documentation/release-1.7/release-notes/v1.7-release-notes.html#support-sanitizing-job-names)
cat <<EOF >>/etc/ood/config/nginx_stage.yml

pun_custom_env:
  OOD_DASHBOARD_TITLE: "Azure OnDemand"
  OOD_BRAND_BG_COLOR: "#53565a"
  OOD_BRAND_LINK_ACTIVE_BG_COLOR: "#fff"
  OOD_JOB_NAME_ILLEGAL_CHARS: "/"
EOF


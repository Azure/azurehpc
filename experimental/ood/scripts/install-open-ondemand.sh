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
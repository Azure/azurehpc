#!/bin/bash

USER=${1:-hpcuser}

yum groupinstall Xfce -y

yum install -y xrdp

eval USER_HOME_DIR=~$USER
echo "xfce4-session" > ${USER_HOME_DIR}/.Xclients
chmod a+x ${USER_HOME_DIR}/.Xclients

systemctl set-default graphical.target
systemctl isolate graphical.target

systemctl enable xrdp
systemctl restart xrdp

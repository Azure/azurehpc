#!/bin/bash

USER=${1:-hpcuser}

yum groupinstall Xfce -y
yum install -y xorg-x11-server-Xorg

eval USER_HOME_DIR=~$USER
echo "xfce4-session" > ${USER_HOME_DIR}/.Xclients
chmod a+x ${USER_HOME_DIR}/.Xclients

sed -i 's#Exec=startxfce4#Exec=/usr/bin/startxfce4#' /usr/share/xsessions/xfce.desktop
sed -i 's#Icon=#Icon=/usr/share/pixmaps/xfce4_xicon1.png#' /usr/share/xsessions/xfce.desktop
echo "Encoding=UTF-8" >> /usr/share/xsessions/xfce.desktop

systemctl set-default graphical.target
systemctl isolate graphical.target

systemctl restart gdm

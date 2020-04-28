#!/bin/bash

yum groupinstall Xfce -y
yum groupinstall "Server with GUI" -y

yum install -y xrdp

echo "xfce4-session" > ~/.Xclients

systemctl get-default
systemctl set-default graphical.target
systemctl isolate graphical.target

systemctl enable xrdp
systemctl restart xrdp

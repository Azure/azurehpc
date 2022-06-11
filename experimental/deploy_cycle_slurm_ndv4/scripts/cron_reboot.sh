#!/bin/bash

if ! [ -f /root/reboot.sh ]; then
	cp $CYCLECLOUD_SPEC_PATH/files/reboot.sh /root
	cp $CYCLECLOUD_SPEC_PATH/files/setup_nvme_heal.sh /root
	cp $CYCLECLOUD_SPEC_PATH/files/max_gpu_app_clocks.sh /root
fi

if ! [ -f /etc/crontab.orig ]; then
	cp /etc/crontab /etc/crontab.orig
	echo "@reboot root /root/reboot.sh" | tee -a /etc/crontab
fi

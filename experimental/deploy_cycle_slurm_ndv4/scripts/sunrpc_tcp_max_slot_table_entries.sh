#!/bin/bash

TCP_MAX_SLOT_TABLE_ENTRIES=128
MODPROBE_FILE=/etc/modprobe.d/sunrpc.conf

echo "options sunrpc tcp_max_slot_table_entries=$TCP_MAX_SLOT_TABLE_ENTRIES" | sudo tee -a $MODPROBE_FILE > /dev/null

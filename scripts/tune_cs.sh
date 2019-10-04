#!/bin/bash

lctl set_param osc.*.max_rpcs_in_flight=256
lctl set_param mdc.*.max_rpcs_in_flight=256
lctl set_param osc.*.max_dirty_mb=1024
lctl set_param osc.*.max_pages_per_rpc=1024
lctl set_param osc.*.checksums=0
lctl set_param ldlm.namespaces.*osc*.lru_size=0
lctl set_param llite.*.max_read_ahead_mb=1024
lctl set_param llite.*.max_read_ahead_per_file_mb=1024

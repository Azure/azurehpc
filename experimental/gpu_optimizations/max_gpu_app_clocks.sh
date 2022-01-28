#!/bin/bash

# Set or reset the application max GPU clock frequencies
# If no arguments, then set Max GPU clock frequencies, if -r argment used then reset the GPU frequencies.

GPU_QUERY="clocks.max.memory,clocks.applications.memory,clocks.max.graphics,clocks.applications.graphics"

for device in {0..7};
do
   if [[ $1 == "-r" ]]; then
      reset_gpu_freq_out=$(nvidia-smi -i $device -rac)
      reset_gpu_freq_out_rc=$?
      if [[ $reset_gpu_freq_out_rc != 0 ]]; then
         echo "Error: nvidia-smi (reset gpu max freqs) did not run correctly, $reset_gpu_freq_out"
      else
	 echo "On GPU Id $device, $reset_gpu_freq_out"
      fi
   else
      gpu_freq_out=$(nvidia-smi -i $device --query-gpu=$GPU_QUERY --format=csv,noheader,nounits)
      gpu_freq_out_rc=$?
      if [[ $gpu_freq_out_rc != 0 ]]
      then
         echo "Error: nvidia-smi (gpu freqs) did not run correctly, $gpu_freq_out"
         exit 1
      fi
      IFS=$', '
      gpu_freq_line=( $gpu_freq_out )
      IFS=$' \t\n'
      if [[ ${gpu_freq_line[0]} -gt ${gpu_freq_line[1]} || ${gpu_freq_line[2]} -gt ${gpu_freq_line[3]} ]]; then
         set_gpu_freq_out=$(nvidia-smi -i $device -ac ${gpu_freq_line[0]},${gpu_freq_line[2]})
         set_gpu_freq_out_rc=$?
         if [[ $set_gpu_freq_out_rc != 0 ]]; then
            echo "Error: nvidia-smi (set gpu max freqs) did not run correctly, $set_gpu_freq_out"
            exit 1
         fi
         echo "On GPU Id $device, $set_gpu_freq_out"
      else
         echo "GPU Id $device, max application GPU clocks are already set, GPU memory is  ${gpu_freq_line[0]} MHz and GPU graphics is ${gpu_freq_line[2]} MHz"
      fi
   fi
done

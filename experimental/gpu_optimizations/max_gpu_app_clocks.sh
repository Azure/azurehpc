#!/bin/bash

# Set the application maximum GPU clock frequencies. (default, no arguments)
# Reset the application  GPU clock frequencies. (-r argument)
# List the application current and maximum GPU clock frequencies. (-l argument)


GPU_QUERY="clocks.max.memory,clocks.applications.memory,clocks.max.graphics,clocks.applications.graphics"


function collect_clocks_data() {
   gpu_freq_out=$(nvidia-smi --query-gpu=$GPU_QUERY --format=csv,noheader,nounits)
   gpu_freq_out_rc=$?
   if [[ $gpu_freq_out_rc != 0 ]]; then
      echo "$gpu_freq_out"
      echo "Error: nvidia-smi (get clock freqs) returned error code $gpu_freq_out_rc"
      exit 1
   fi
   IFS=$'\n'
   gpu_freq_out_lines=( $gpu_freq_out )
   IFS=$' \t\n'
}


number_gpus=$(nvidia-smi -i 0 --query-gpu=count --format=csv,noheader)
for ((i=0; i<$number_gpus; i++))
do
   if [[ $1 == "-r" ]]; then
      reset_gpu_freq_out=$(nvidia-smi -i $i -rac)
      reset_gpu_freq_out_rc=$?
      if [[ $reset_gpu_freq_out_rc != 0 ]]; then
         echo "Error: GPU Id $i: nvidia-smi (reset gpu max freqs) did not run correctly, $reset_gpu_freq_out"
         exit 1
      else
	 echo "On GPU Id $device, $reset_gpu_freq_out"
      fi
   else
      collect_clocks_data
      IFS=$', '
      gpu_freq_out_line=( ${gpu_freq_out_lines[$i]} )
      IFS=$' \t\n'
      if [[ $1 == "-l" ]]; then
	      echo "GPU Id $i: GPU memory freq (max,current)= (${gpu_freq_out_line[0]},${gpu_freq_out_line[1]}) MHz, GPU graphics freq (max,current) = (${gpu_freq_out_line[2]},${gpu_freq_out_line[3]}) MHz" 
      elif [[ ${gpu_freq_out_line[0]} -gt ${gpu_freq_out_line[1]} || ${gpu_freq_out_line[2]} -gt ${gpu_freq_out_line[3]} ]]; then
         set_gpu_freq_out=$(nvidia-smi -i $i -ac ${gpu_freq_out_line[0]},${gpu_freq_out_line[2]})
         set_gpu_freq_out_rc=$?
         if [[ $set_gpu_freq_out_rc != 0 ]]; then
            echo "Error: GPU Id $i: nvidia-smi (set gpu max clock freqs) did not run correctly, $set_gpu_freq_out"
            exit 1
         fi
         echo "On GPU Id $i: $set_gpu_freq_out"
      else
         echo "GPU Id $i: max application GPU clocks are already set, GPU memory is  ${gpu_freq_out_line[0]} MHz and GPU graphics is ${gpu_freq_out_line[2]} MHz"
      fi
   fi
done

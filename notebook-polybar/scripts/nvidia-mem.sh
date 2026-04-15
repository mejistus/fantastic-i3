#!/bin/sh
# nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | awk '{ print "󰍛 ", ""$1"","%"}'
# nvidia_mem(){
MEM_USE=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits) 
MEM_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits) 
MEM_USE_PERCENT=$(($MEM_USE/$MEM_TOTAL)) 
per=100
echo "$MEM_USE $MEM_TOTAL $per"| awk '{printf("󰍛 %d %\n" , $1/$2*$3) }'
# }

# nvidia-mem()

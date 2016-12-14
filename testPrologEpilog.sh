#!/bin/sh
#
# Authors: Mozhgan Kabiri Chimeh, Paul Richmond
# Contact: m.kabiri-chimeh@sheffield.ac.uk
#
# Startup script to allocate GPU devices.
# Based on https://github.com/kyamagu/sge-gpuprolog
#
# test script for both Prolog and Epilog

#have a script file qstat which emulates what a qstat job would return
#define JOB_ID
#define node_id

JOB_ID=1 # num gpus
node_number=1 # user defined

# Output the directory status list for lock files
check_locks_func(){
echo
echo "------------------------------------"
for device_id in $device_ids
do
  lockfile=/tmp/lock_$node_number"_device"$device_id
  if [ -d $lockfile ]
  then
     echo "$lockfile exists"
  else
     echo "no lock exists"
  fi
done
echo "------------------------------------"
echo
}

# Output current list of devices IDS from NVIDIA-SMI
deviceId_func(){
device_ids=$(nvidia-smi -L | cut -f1 -d":" | cut -f2 -d" " | xargs shuf -e)
echo "Current list of devices: $device_ids"
}

#################################################

echo "START ...."
export JOB_ID=1 # num gpus
export node_number=1 # user defined


deviceId_func
check_locks_func

echo "executing Prolog ..................."
echo "source prolog.sh"
./prolog.sh

deviceId_func
check_locks_func

echo "executing Prolog ..................."
./epilog.sh


check_locks_func
echo "DONE"
 

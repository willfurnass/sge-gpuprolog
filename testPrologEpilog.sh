#!/bin/bash
#
# Authors: Mozhgan Kabiri Chimeh, Paul Richmond
# Contact: m.kabiri-chimeh@sheffield.ac.uk
#
# Startup script to allocate GPU devices.
# Based on https://github.com/kyamagu/sge-gpuprolog
#
# The script is written to test if both Prolog and Epilog scripts are working
# For this purpose, we created another script called 'qstat' to emulate what the real 'qstat' command does.
# To execute, simply run ./testPriloEpilog $1 , where $1 is the number of gpus. This is actually the $JOB_ID, but we as we use a fake one, we set this as the number of GPUs user requested

# The system will look for executables in current directory without a "./". 
export PATH=$PATH:. 


JOB_ID=$1 # num gpus

# Output the directory status list for lock files
check_locks_func() {
  echo
  echo "------------------------------------"
  for device_id in $device_ids; do
    lockfile="/tmp/sge-gpu/lock_device_$device_id"
    if [[ -d $lockfile ]]; then 
      echo "$lockfile exists"
    else
      echo "no lock exists on $lockfile"
    fi
  done
  echo "------------------------------------"
  echo
}

# Output current list of devices IDS from nvidia-smi
deviceId_func() {
  device_ids="$(nvidia-smi -L | cut -f1 -d":" | cut -f2 -d" " | xargs shuf -e)"
  echo "Current list of devices: $device_ids"
}

#################################################

# Create directory to store lock files
mkdir -p /tmp/sge-gpu
find /tmp/sge-gpu/ -type d -exec rmdir {} \;
mkdir -p /tmp/dummy-sge-spool-dir
find /tmp/dummy-sge-spool-dir/ -type f -exec rm {} \;

# Create dummy Sun Grid Engine job spool directory
export $SGE_JOB_SPOOL_DIR=/tmp/dummy-sge-spool-dir 
mkdir -p $SGE_JOB_SPOOL_DIR
truncate --size=0 $SGE_JOB_SPOOL_DIR/environment

echo "START ...."
export JOB_ID=$1 # num gpus

deviceId_func
check_locks_func

echo "executing Prolog ..................."
echo "source ./prolog.sh"
bash prolog.sh

# setting NVIDIA sample path to check the number of visible devices, make sure to compile/build the deviceQuery before hand
~/NVIDIA_CUDA-8.0_Samples/1_Utilities/deviceQuery/deviceQuery  -noprompt | egrep "^Device"
check_locks_func

echo "executing Epilog ..................."
bash ./epilog.sh

check_locks_func
echo "DONE"

#!/bin/sh
#
# Authors: Mozhgan Kabiri Chimeh, Paul Richmond
# Contact: m.kabiri-chimeh@sheffield.ac.uk
#
# Startup script to allocate GPU devices.
# Based on https://github.com/kyamagu/sge-gpuprolog
#

# Query how many gpus to allocate.Using qstat
NGPUS=$(qstat -j $JOB_ID | \
        sed -n "s/hard resource_list:.*gpu=\([[:digit:]]\+\).*/\1/p")
if [ -z $NGPUS ] # check if NGPUS is null, then exit
then
  exit 0
fi
if [ $NGPUS -le 0 ]  # check if NGPUS are less than equal 0, then exit
then
  exit 0
fi


# Allocate and lock GPUs. We will populate SGE_GPU with the device IDs that the job should use.
SGE_GPU=""
# Counter for free devices that we have obtained a lock on
i=0
# Get a list of all device IDS which will be space seperated
device_ids=$(nvidia-smi -L | cut -f1 -d":" | cut -f2 -d" " | xargs shuf -e)

#loop through the device IDs and check to see if a lock can be obtained for the device
for device_id in $device_ids
do
  #lock file is specific for each ShARC node and each device combination (node_number is a SGE prolog variable)
  lockfile=/tmp/lock_$node_number"_device"$device_id
  #use mkdir to obtain a lock (will fail if file exists)
  if mkdir $lockfile
  then
    # We have obtained a lock so can have exclusive access to this GPU id. Add the ID to SGE_GPU
    SGE_GPU="$SGE_GPU $device_id"
    # Increment i counter to reflect that we have obtained a GPU for the job
    i=$(expr $i + 1)
    if [ $i -ge $NGPUS ] # check if reserved num gpus are greater than requested number of GPUS
    then
      break
    fi
  fi
done

 # Check if reserved num gpus are less than requested number of GPUS. If this is true then there were not enough free devices for the job and the scheduling should fail
if [ $i -lt $NGPUS ]
then
  echo "ERROR: Only reserved $i of $NGPUS requested devices."
  exit 1
fi


# Set the cuda devices visible. This will re-enumerate the devices to users. i.e. a job requesting 1 device which locks device_id=3 will see this as device 0 in nvidia-smi
SGE_GPU="$(echo $SGE_GPU | sed -e 's/^ //' | sed -e 's/ /,/g')" # seperating device_ids with comma

# Set the environment.
# IMPORTANT: You need to source this script (use source to execute it), so that the variable modified by the script will be available after the script completes
export CUDA_VISIBLE_DEVICES=$SGE_GPU 

exit 0

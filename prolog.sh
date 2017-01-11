#!/bin/bash
#
# Authors: Mozhgan Kabiri Chimeh, Paul Richmond, Will Furnass
# Contact: m.kabiri-chimeh@sheffield.ac.uk
#
# Sun Grid Engine prolog script to allocate GPU devices.
# Based on https://github.com/kyamagu/sge-gpuprolog

source /etc/profile.d/SoGE.sh

# Query how many gpus to allocate (using qstat)
NGPUS="$(qstat -j $JOB_ID | sed -n "s/hard resource_list:.*gpu=\([[:digit:]]\+\).*/\1/p")" || true

# Exit if NGPUs is null
[[ -z $NGPUS ]] && exit 0

# Exit if NGPUS <= 0
[[ $NGPUS -le 0 ]] && exit 0

# Allocate and lock GPUs. We will populate SGE_GPU with the device IDs that the job should use.
SGE_GPU=""
# Counter for free devices that we have obtained a lock on
i=0
# Get a list of all device IDS which will be space seperated
device_ids=$(nvidia-smi -L | cut -f1 -d":" | cut -f2 -d" " | xargs shuf -e)

# Loop through the device IDs and check to see if a lock can be obtained for the device
for device_id in $device_ids; do
  # Lock file is specific for each ShARC node and each device combination ('node_number' is a SGE prolog variable)
  lockfile="/tmp/sge-gpu/lock_device_${device_id}"

  # Use 'mkdir' to obtain a lock (will fail if file exists)
  if mkdir $lockfile; then 
    # We have obtained a lock so can have exclusive access to this GPU id. Add the ID to SGE_GPU
    SGE_GPU="$SGE_GPU $device_id"
    # Increment i counter to reflect that we have obtained a GPU for the job
    i=$(expr $i + 1)
    if [[ $i -ge $NGPUS ]]; then # check if reserved num gpus are greater than requested number of GPUS
      break
    fi
  fi
done

# Check if reserved num GPUs are less than requested number of GPUS. 
# If this is true then there were not enough free devices for the job 
# and the scheduling should fail
if [[ $i -lt $NGPUS ]]; then
  echo "ERROR: Only reserved $i of $NGPUS requested devices."
  exit 100
fi

# Set the cuda devices visible. This will re-enumerate the devices to users. 
# i.e. a job requesting 1 device which locks device_id=3 will see this as device 0 in nvidia-smi
SGE_GPU="$(echo $SGE_GPU | sed -e 's/^ //' | sed -e 's/ /,/g')" # seperating device_ids with comma

# Set the environment (NB cannot just 'export' CUDA_VISIBLE_DEVICES as this script is not 'source'd)
echo "CUDA_VISIBLE_DEVICES=$SGE_GPU" >> $SGE_JOB_SPOOL_DIR/environment

#exit 0

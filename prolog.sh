#!/bin/bash
#
# Authors: Mozhgan Kabiri Chimeh, Paul Richmond, Will Furnass
# Contact: w.furnass@sheffield.ac.uk
#
# Sun Grid Engine prolog script to allocate GPU devices.
# Based on https://github.com/kyamagu/sge-gpuprolog

# Ensure various SGE env vars are set
source /etc/profile.d/SoGE.sh
# Ensure SGE_GPU_LOCKS_DIR env var is set
source /etc/profile.d/sge_gpu_locks.sh

# Query how many gpus to allocate (for serial process or per SMP or MPI slot)
NGPUS="$(qstat -j $JOB_ID | sed -n "s/hard resource_list:.*gpu=\([[:digit:]]\+\).*/\1/p")" || true

# Exit if NGPUs is null or <= 0
[[ -z $NGPUS || $NGPUS -le 0 ]] && exit 0

# Scale GPUs with number of requested cores if using the 'smp' Grid Engine Parallel Environment
# (as the current scheduler configuration is for the 'gpu' countable complex consumable 
# to scale with the number of requested slots)
if [[ -n $PE && $PE == 'smp' && -n $NSLOTS && NSLOTS -gt 1 ]]; then
    NGPUS=$(( $NGPUS * $NSLOTS ))
fi

# Allocate and lock GPUs. We will populate SGE_GPU with the device IDs that the job should use.
SGE_GPU=""
# Counter for free devices that we have obtained a lock on
i=0
# Get a list of all device IDS 
# (don't use nvidia-smi as it is slow)
device_ids=$(seq 0 $(( $(ls /proc/driver/nvidia/gpus/ | wc -l) -1 )) | shuf)

# Loop through the device IDs and check to see if a lock can be obtained for the device
for device_id in $device_ids; do
  # Lock file is specific for each ShARC node and each device combination
  lockfile="${SGE_GPU_LOCKS_DIR}/lock_device_${device_id}"

  # Use 'mkdir' to obtain a lock (will fail if file exists)
  if mkdir $lockfile &> /dev/null; then 
    # We have obtained a lock so can have exclusive access to this GPU id. Add the ID to SGE_GPU
    SGE_GPU="$SGE_GPU $device_id"
    # Increment i counter to reflect that we have obtained a GPU for the job
    i=$(expr $i + 1)
    # Check if reserved num gpus are greater than requested number of GPUS
    if [[ $i -ge $NGPUS ]]; then 
      break
    fi
  fi
done

# If running this script as part of stand-alone tests (without Grid Engine) then
# check if fewer GPUs were reserved than requested.
# If this is true then there were not enough free devices for the job 
# and the (dummy) scheduling should fail.
# This logic is not needed if running this script as a Grid Engine prolog script 
# as by the time this runs the scheduler has already checked 
# that there are a sufficient number of free GPUs to satisfy the request.
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

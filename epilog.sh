#!/bin/bash
#
# Authors: Mozhgan Kabiri Chimeh, Paul Richmond, Will Furnass
# Contact: m.kabiri-chimeh@sheffield.ac.uk
#
# Sun Grid Engine Epilog script to free GPU lock files for devices used by a job.
# Based on https://github.com/kyamagu/sge-gpuprolog

# Ensure SGE_GPU_LOCKS_DIR env var is set
source /etc/profile.d/sge_gpu_locks.sh

# Reformat the list of device ids used by the job (into space seperated)
device_ids="$(echo $CUDA_VISIBLE_DEVICES | sed -e "s/,/ /g")"

# Loop through through the device IDs and free the lockfile
for device_id in $device_ids; do
  # Lock file is specific for each ShARC node and each device combination
  lockfile="${SGE_GPU_LOCKS_DIR}/lock_device_${device_id}"

  # Check dir exists then remove the lockfile
  if [[ -d $lockfile ]]; then
    rmdir $lockfile
  fi
done
#exit 0

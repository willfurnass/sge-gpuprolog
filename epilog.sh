#!/bin/sh
#
# Authors: Mozhgan Kabiri Chimeh, Paul Richmond
# Contact: m.kabiri-chimeh@sheffield.ac.uk
#
# Epilog script to free GPU lock files for devices used by a job.
# Based on https://github.com/kyamagu/sge-gpuprolog
#


# Reformat the list of device ids used by the job (into space seperated)
device_ids=$(echo $CUDA_DEVICE_VISIBLE | sed -e "s/,/ /g")

# Loop through through the device IDs and free the lockfile
for device_id in $device_ids
do
  #lock file is specific for each ShARC node and each device combination (node_number is a SGE prolog variable)
  lockfile=/tmp/lock_$node_number"_device"$device_id
  # Check dir exists then remove the lockfile
  if [ -d $lockfile ]
  then
    rmdir -f $lockfile
  fi
done
exit 0

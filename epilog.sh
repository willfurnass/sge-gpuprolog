#!/bin/sh
#
# Finish script to release GPU devices.
#
# Based on https://github.com/kyamagu/sge-gpuprolog

:'
# Check if the environment file is readable.
ENV_FILE=$SGE_JOB_SPOOL_DIR/environment
if [ ! -f $ENV_FILE -o ! -r $ENV_FILE ]
then
  exit 1
fi
'

:'
device_ids=$(grep SGE_GPU $ENV_FILE | \
             sed -e "s/,/ /g" | \
             sed -n "s/SGE_GPU=\(.*\)/\1/p" | \
             xargs shuf -e)
'

# Remove lock files.
device_ids=$(echo $CUDA_DEVICE_VISIBLE | sed -e "s/,/ /g")

for device_id in $device_ids
do
  #lockfile=/tmp/lock-nvidia$device_id
  lockfile=/tmp/lock_$(node_number)_device$(device_id)
  if [ -d $lockfile ]
  then
    rmdir -f $lockfile
  fi
done
exit 0

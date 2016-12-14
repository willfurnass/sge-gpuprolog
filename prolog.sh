#!/bin/sh
#
# Startup script to allocate GPU devices.
#
# Based on https://github.com/kyamagu/sge-gpuprolog

# Query how many gpus to allocate.
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
NGPUS=$(expr $NGPUS \* ${NSLOTS=1})

:'
# Check if the environment file is writable.
ENV_FILE=$SGE_JOB_SPOOL_DIR/environment
if [ ! -f $ENV_FILE -o ! -w $ENV_FILE ]
then
  exit 1
fi
'

# Allocate and lock GPUs.
SGE_GPU=""
i=0
device_ids=$(nvidia-smi -L | cut -f1 -d":" | cut -f2 -d" " | xargs shuf -e)
for device_id in $device_ids
do
  #lockfile=/tmp/lock-gpu$device_id
  lockfile=/tmp/lock_$(node_number)_device$(device_id)
  if mkdir $lockfile
  then
    SGE_GPU="$SGE_GPU $device_id"
    i=$(expr $i + 1)
    if [ $i -ge $NGPUS ] # check if reserved num gpus are greater than requested number of GPUS
    then
      break
    fi
  fi
done

if [ $i -lt $NGPUS ] # check if reserved num gpus are less than requested number of GPUS
then
  echo "ERROR: Only reserved $i of $NGPUS requested devices."
  exit 1
fi

:'
echo SGE_GPU="$(echo $SGE_GPU | sed -e 's/^ //' | sed -e 's/ /,/g')" >> $ENV_FILE
'

# no need to write into the enviroment file as above, we simply set the set cuda devices visible
SGE_GPU="$(echo $SGE_GPU | sed -e 's/^ //' | sed -e 's/ /,/g')" # seperating device_ids with comma

# Set the environment.
export CUDA_DEVICE_VISIBLE=$SGE_GPU # you need to source this (use source to execute it), so that the variable modified by the script will be available after the script completes
exit 0

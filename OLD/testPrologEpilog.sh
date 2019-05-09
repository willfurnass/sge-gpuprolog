#!/bin/bash
#
# Authors: Mozhgan Kabiri Chimeh, Paul Richmond, Will Furnass
# Contact: m.kabiri-chimeh@sheffield.ac.uk
#
# Startup script to allocate GPU devices.
# Based on https://github.com/kyamagu/sge-gpuprolog
#
# The script is written to test if both the prolog and epilog scripts are working.
# For this purpose, we created another script called 'qstat' to 
# emulate what the real 'qstat' command does.
#
# Requires the 'deviceQuery' program included with the CUDA samples

export SGE_GPU_LOCKS_DIR=/tmp/sge-gpu-test
export SGE_JOB_SPOOL_DIR=/tmp/dummy-sge-spool-dir 
# The system will look for executables in current directory without a "./". 
export PATH=${PATH}:. 

usage() {
    echo "Usage: $0 <num-gpus> <cuda-deviceQuery-prog>" 1>&2
    exit 1
}

# Check the command-line arguments
[[ $# -eq 2 ]] || usage
[[ $1 -gt 0 ]] || usage
# Reuse $JOB_ID: set this as the number of GPUs user requested (WF: ?)
JOB_ID=$1 # num gpus
DEVICE_QUERY="$2"
[[ -x $DEVICE_QUERY ]] || usage

# DELETEME?
# To execute, simply run ./testPrologEpilog.sh $1, where $1 is the number of gpus. 
# DELETEME?

# Output the directory status list for lock files
check_locks_func() {
    echo
    echo "------------------------------------"
    for device_id in $device_ids; do
        lockfile="${SGE_GPU_LOCKS_DIR}/lock_device_$device_id"
        if [[ -d $lockfile ]]; then 
            echo "Lock file $lockfile exists"
        else
            echo "Lock file $lockfile does not exist"
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
mkdir -p $SGE_GPU_LOCKS_DIR
find $SGE_GPU_LOCKS_DIR -mindepth 1 -type d -empty -delete

# Create dummy Sun Grid Engine job spool directory and job environment file
mkdir -p $SGE_JOB_SPOOL_DIR
truncate --size=0 $SGE_JOB_SPOOL_DIR/environment

echo "START ..."
export JOB_ID=$1 # num gpus

deviceId_func
check_locks_func

echo "Executing prolog script as a subprocess: "
bash prolog.sh

# Display the number of visible devices
$DEVICE_QUERY -noprompt | egrep "^Device"
check_locks_func

echo "Executing epilog script"
bash epilog.sh

check_locks_func
echo "DONE"

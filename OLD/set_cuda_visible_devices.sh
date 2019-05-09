#! /bin/bash
# Set CUDA_VISIBLE_DEVICES to the indexes of the least busy NVIDIA GPUs in the machine.
# Works for 
#  - Grid Engine jobs that request multiple GPUs per slot
#  - Grid Engine jobs that request the 'smp' parallel environment and multiple slots
#
# Only sets CUDA_VISIBLE_DEVICES if not already set.

set -euo pipefail

# Ensure various SGE env vars are set
source /etc/profile.d/SoGE.sh


function is_pe_single_node_only {
    # Is a  parallel environment (first and only argument) single-node only?

    local pe="$1"
    qconf -sp $pe | grep -Eq '^allocation_rule\s*\$pe_slots$'
}


function get_total_job_gpus {
    local jobid=$1
    # Query how many gpus to allocate (for serial process or per SMP parallel
    # environment; does not work for MPI parallel environments)
    local NGPUS="$(qstat -j $jobid | sed -n "s/hard resource_list:.*gpu=\([[:digit:]]\+\).*/\1/p")" || true

    # Exit if NGPUs is null or <= 0
    [[ -z $NGPUS || $NGPUS -le 0 ]] && exit 0

    # Scale GPUs with number of requested cores if using the 'smp' Grid Engine Parallel Environment
    # (as the current scheduler configuration is for the 'gpu' countable complex consumable 
    # to scale with the number of requested slots)
    if [[ -n $PE ]] && pe_is_single_node_only $PE && [[ -n $NSLOTS ]] && [[ NSLOTS -gt 1 ]]; then
        NGPUS=$(( NGPUS * NSLOTS ))
    fi
    echo $NGPUS
}


function get_n_least_busy_nvidia_idxs {
    # Query device info to select the device id with the least chance of
    # utilsiation. Sorts by free memory, then gpu utilsation, memory
    # utilsiation, temperature and then id
     
    # n, the first and only function parameter, defaults to 1
    local n=${1-1}

    nvidia-smi \
            --query-gpu=index,name,memory.free,utilization.gpu,utilization.memory,temperature.gpu \
            --format=csv,noheader,nounits | \
        sort -t, -k3,3nr -k4,4n -k5,5n -k6,6n -k1,1nr | \
        head -n "$n" | \
        cut -d, -f1 | \
        paste -sd,
}


function set_cuda_visible_devices {
    # Main function

    if [[ -z "${JOB_ID}" ]]; then
        echo "JOB_ID not set; exiting" 2>&1
    fi
    # If CUDA_VISIBLE_DEVICE is not already set
    if [ -z "$CUDA_VISIBLE_DEVICES" ]; then
        export CUDA_VISIBLE_DEVICES="$(set_cuda_visible_devices)"
        echo "Setting CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES}"
    else
        echo "CUDA_VISIBLE_DEVICES is already set. CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES}"
    fi
}


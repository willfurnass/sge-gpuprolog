#!/bin/bash

function get_gpu_req_per_slot {
    declare -ri job_id=$1

    declare -ri gpu_req_per_slot="$(qstat -j $job_id | sed -n "s/hard resource_list:.*gpu=\([[:digit:]]\+\).*/\1/p"))"
    echo $gpu_req_per_slot
}

function get_total_gpus_req {
    declare -ri gpus_per_slot_req
    declare -r  parallel_env_req
    declare -ri num_slots_req

    declare -i total_gpus_req

    # SMP parallel environment
    if [[ -n $parallel_env_req && $parallel_env_req == 'smp' && -n $num_slots_req && $num_slots_req -gt 1 ]]; then
        $total_gpus_req=$(( $gpu_req_per_slot * $num_slots_req ))
    else
        # serial environment (NB MPI-related parallel environments not supported yet)
        $total_gpus_req=$gpu_req_per_slot
    fi
    echo $total_gpus_req
}

function get_all_gpu_dev_ids_shuffled {

    declare -r device_ids="$(seq 0 $(( $(ls /proc/driver/nvidia/gpus/ | wc -l) -1 )) | shuf)"
    echo $device_ids
}

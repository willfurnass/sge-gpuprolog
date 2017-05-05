#!/usr/bin/env python

# Authors: Will Furnass, Mozhgan Kabiri Chimeh, Paul Richmond
# Contact: w.furnass@sheffield.ac.uk
#
# Sun Grid Engine prolog script to allocate GPU devices.
# Inspired by https://github.com/kyamagu/sge-gpuprolog

import os
import logging
import sys
from random import shuffle

logging.basicConfig(stream=sys.stdout, level=logging.WARNING)

# TODO
# Ensure various SGE env vars are set
#source /etc/profile.d/SoGE.sh
# Ensure SGE_GPU_LOCKS_DIR env var is set
#source /etc/profile.d/sge_gpu_locks.sh


def get_gpus_req_per_slot(job_id):
    pass


def get_total_gpus_req(gpus_per_slot, parallel_env, num_slots):
    pass


def get_all_gpu_dev_ids():
    """ Get a list of all GPU IDs.

    (don't use `nvidia-smi` as it is slow)
    """
    proc_fs_path = os.path.join(os.sep, 'proc', 'driver', 'nvidia', 'gpus')
    pci_ids = os.listdir(proc_fs_path)
    return list(range(0, len(pci_ids)))


def set_var_in_job_env(acquired_gpus):
    """Set CUDA_VISIBLE_DEVICES in the job's env to a comma-separated list
    of GPU IDs."""
    job_env_file = os.path.join(os.environ['SGE_JOB_SPOOL_DIR'],
                                'environment')
    with open(job_env_file, 'w') as f:
        # Want to assign a comma-separated list of GPU IDs
        # to a variable in the job's environment
        shell_assignment = "CUDA_VISIBLE_DEVICES={}" \
                        .format(','.join(map(str, acquired_gpus)))
        print(shell_assignment, file=f)


def prolog():
    total_gpus_req = 0  # TODO: DUMMY STMT
    sge_gpu_locks_dir = os.environ['SGE_GPU_LOCKS_DIR']  # TODO: WHAT IF DOESN'T EXIST?

    dev_ids = get_all_gpu_dev_ids()
    dev_ids = shuffle(dev_ids)

    acquired_gpus = []

    for dev in dev_ids:
        # Lock is specific for each node and device combination
        lock_dir = "{}/lock_device_{}".format(sge_gpu_locks_dir, dev)
        try:
            # Use 'mkdir' to obtain a lock
            os.mkdir(lock_dir)
        except FileExistsError:
            pass
        logging.debug("Acquired exclusive lock on GPU {} ({})"
                      .format(dev, lock_dir))
        acquired_gpus.append(dev)

        if len(acquired_gpus) >= total_gpus_req:
            logging
            break

    if len(acquired_gpus) < total_gpus_req:
        logging.warning("Only reserved {} of {} requested devices!"
                        .format(len(acquired_gpus), total_gpus_req))
        sys.exit(100)

    set_var_in_job_env(acquired_gpus)

    sys.exit(0)


if __name__ == '__main__':
    prolog()

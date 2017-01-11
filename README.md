Grid Engine + GPU prolog and epilog scripts
===========================================

Scripts to manage NVIDIA GPU devices in Grid Engine (tested with Son of Grid Engine 8.1.9).

Son of Grid Engine 8.1.9 and earlier do not feature the 
RSMAP functionality that is implemented in recent Univa Grid Engine. 
The ad-hoc scripts in this package implement resource allocation for NVIDIA devices.


Installation
------------

First, set up consumable complex `gpu`.

    qconf -mc

    #name               shortcut   type        relop   requestable consumable default  urgency
    #----------------------------------------------------------------------------------------------
    gpu                 gpu        INT         <=      YES         YES        0        0


At each exec-host, add the `gpu` resource complex. For example:

    qconf -aattr exechost complex_values gpu=1 node001

Set up `prolog` and `epilog` scripts for the relevant queue(s):

    qconf -mq gpu.q

    prolog                sge@/path/to/sge-gpuprolog/prolog.sh
    epilog                sge@/path/to/sge-gpuprolog/epilog.sh

Note that the `sge@` prefix means that the prolog and epilog scripts will be run as the `sge` user, not as the end-user.

Alternatively, you may set up a parallel environment for GPU and set
`start_proc_args` and `stop_proc_args` to the packaged scripts.

Usage
-----

Request `gpu` resource in the designated queue.

    qsub -q gpu.q -l gpu=1 gpujob.sh

The job script can access `CUDA_VISIBLE_DEVICES` variable.

    #!/bin/sh
    echo $CUDA_VISIBLE_DEVICES

The variable contains a comma-delimited device IDs, such as `0` or `0,1,2`
depending on the number of `gpu` resources to be requested. Use the device ID
for `cudaSetDevice()`.

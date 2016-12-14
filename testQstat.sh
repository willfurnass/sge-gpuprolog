#!/bin/sh
# to test if qstat emulator works 
:'
./qstat.sh -j $1 >temp

NGPUS=$(sed -n "s/hard resource_list:.*gpu=\([[:digit:]]\+\).*/\1/p" temp)
echo $NGPUS
'

NGPU=$(./qstat -j $1 | \
        sed -n "s/hard resource_list:.*gpu=\([[:digit:]]\+\).*/\1/p")

echo $NGPU

device_id=1
node_number=2

lockfile=/tmp/lock_$node_number"_device"$device_id

echo $lockfile

#!/bin/sh
# to test if qstat emulator works 
:'
./qstat.sh -j $1 >temp

NGPUS=$(sed -n "s/hard resource_list:.*gpu=\([[:digit:]]\+\).*/\1/p" temp)
echo $NGPUS
'

NGPU=$(./qstat.sh -j $1 | \
        sed -n "s/hard resource_list:.*gpu=\([[:digit:]]\+\).*/\1/p")

echo $NGPU

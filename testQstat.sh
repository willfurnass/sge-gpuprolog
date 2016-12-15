#!/bin/sh
# The script is written to test if qstat emulator works.

# The system will look for executables in current directory without a "./". 
export PATH=$PATH:. 

NGPU=$(qstat -j $1 | \
        sed -n "s/hard resource_list:.*gpu=\([[:digit:]]\+\).*/\1/p")

echo $NGPU


#!/bin/bash
LOCKDIR=/var/run/lock/cuda
DEVMODE=0660
DEVGROUP=root
DEBUG=0

if [[ "$SGE_TASK_ID" == "undefined" ]]; then
    SGE_TASK_ID=1
fi
if [[ "$DEBUG" -ne 0 ]]; then
  echo "Starting epilog $JOB_ID.${SGE_TASK_ID}" >> /tmp/epilog.log
fi

lockfiles="${LOCKDIR}/gpu*"

if [[ "$DEBUG" -ne 0 ]]; then
    echo "$lockfiles" >> /tmp/epilog.log
fi

for lock in $lockfiles; do
    /usr/bin/grep " ${JOB_ID} ${SGE_TASK_ID} " "${lock}" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        minor=$(/usr/bin/cut -d' ' -f4 "${lock}")
        locked=$(/usr/bin/cut -d' ' -f7 "${lock}")
        # Release the lock
        if [[ "${locked}" -eq 1 ]]; then
            if [[ "$DEBUG" -ne 0 ]]; then
                echo "Unlocking dev-special $minor" >> /tmp/epilog.log
            fi
            /usr/bin/chgrp ${DEVGROUP} "/dev/nvidia${minor}"
            /usr/bin/chmod ${DEVMODE} "/dev/nvidia${minor}"
        fi
        if [[ "$DEBUG" -ne 0 ]]; then
                echo "Unlocking lock file $lock" >> /tmp/epilog.log
        fi
        /usr/bin/rm -f "${lock}"
    fi
done

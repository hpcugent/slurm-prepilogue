#!/bin/bash
#
# Copyright 2018-2026 Ghent University
#
# This file is part of slurm-prepilogue
# originally created by the HPC team of Ghent University (http://ugent.be/hpc/en),
# with support of Ghent University (http://ugent.be/hpc),
# the Flemish Supercomputer Centre (VSC) (https://www.vscentrum.be),
# the Hercules foundation (http://www.herculesstichting.be/in_English)
# and the Department of Economy, Science and Innovation (EWI) (http://www.ewi-vlaanderen.be/en).
#
# All rights reserved.
#
# #

LOGGER=/usr/bin/logger


function user_ipcs_cleanup(){
    # Called at end of last job by user to:
    #  * shared memory segments that have no processes attached

    ${LOGGER} -p local0.alert "Starting user_ipcs_cleanup() for ${SLURM_JOB_USER} from ${SLURM_JOB_ID}"

    # kill leftover allocated shared memory
    for S in $(/usr/bin/ipcs -m | awk -v user=${SLURM_JOB_USER} ' \
            /^key/ { \
                for (i=1; i<=NF; i++) { \
                    f[$i] = i \
                } \
            } \
            { \
                if ($f["owner"] == user && $f["nattch"] == 0) { \
                    print $f["shmid"]; \
                } \
            }' \
    ); do
        /usr/bin/ipcrm -m "$S"
    done

    ${LOGGER} -p local0.alert "Finished user_ipcs_cleanup() for ${SLURM_JOB_USER} from ${SLURM_JOB_ID}"
}

if [ x"$SLURM_UID" = "x" ] ; then
    exit 0
fi

if [ x"$SLURM_JOB_ID" = "x" ] ; then
    exit 0
fi


#
# Only run for valid VSC user IDs
#
if [ "$SLURM_UID" -lt 2500000 ] ; then
    exit 0
fi

${LOGGER} -p local0.alert "********  starting $0 for job $SLURM_JOB_ID"

user_ipcs_cleanup

${LOGGER} -p local0.alert "********  finished $0 for job $SLURM_JOB_ID"

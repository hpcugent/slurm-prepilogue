#!/usr/bin/bash

source $(dirname "$0")/functions.sh

PROLOG_CONF=/etc/slurm/prolog.conf

if [ -e ${PROLOG_CONF} ]
then
    . $PROLOG_CONF
fi

if [ -z "${NRPE_CHECKS}" ]
then
    log "$0 no prolog nrpe checks defined (job ${SLURM_JOBID} user ${SLURM_JOB_USER})"
    exit 0
fi

for check in ${NRPE_CHECKS}; do
    log "$0 run prolog nrpe check $check for job ${SLURM_JOBID} user ${SLURM_JOB_USER}"
    OUTPUT=$(runnrpe -c $check)
    ec=$?
    if [ $ec -gt 0 ]; then
        log "$0 nrpe check $check for job ${SLURM_JOBID} failed: ${OUTPUT}"
        set_drain "nrpe check $check: ${OUTPUT}"
        exit 2
    fi
done

exit 0

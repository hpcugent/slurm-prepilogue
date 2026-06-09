#!/usr/bin/bash

source "$(dirname "$0")"/functions.sh

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

LOCKFILE="/run/lock/slurm-prolog.nrpe.lock"
LOCK_TIMEOUT=30
exec 9> $LOCKFILE

# Blocking lock with a timeout: nrpe checks are for the entire host: only 1
# check should run at the same time. When that check is done, the prologs for
# other jobs, who are waiting for the lock, can use the result from the cache
# file.
if flock -w "$LOCK_TIMEOUT" 9
then
    logger "prolog nrpe checks for job ${SLURM_JOBID}: lock ok"
else
    set_drain "prolog nrpe checks for job ${SLURM_JOBID}: lock timeout"
    exit 1
fi

STAT_CACHE="/var/tmp/prolog.nrpe.cache.ts"
CACHE_THRESHOLD=60

cache_ts=$(stat -c "%Y" $STAT_CACHE)
now=$(date +%s)
if [ $((cache_ts)) -gt $((now - CACHE_THRESHOLD)) ]; then
    cache_result=$(cat "$STAT_CACHE")
    logger "prolog nrpe checks for job ${SLURM_JOBID}: cache recent: exit value $cache_result"
    # use cached good/bad result
    exit "$cache_result"
fi

for check in ${NRPE_CHECKS}; do
    log "$0 run prolog nrpe check $check for job ${SLURM_JOBID} user ${SLURM_JOB_USER}"
    OUTPUT=$(runnrpe -c "$check")
    ec=$?
    if [ $ec -gt 0 ]; then
        log "$0 nrpe check $check for job ${SLURM_JOBID} failed: ${OUTPUT}"
        set_drain "nrpe check $check: ${OUTPUT}"
        echo 2 > $STAT_CACHE
        exit 2
    fi
done

echo 0 > $STAT_CACHE
exit 0

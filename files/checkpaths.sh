#!/bin/bash
# #
# Copyright 2018-2018 Ghent University
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

if [ -z "${1+x}" ]; then
    # get the job's owner from the SLURM environment
    userid="${SLURM_JOB_USER}"
else
    userid="$1"
fi

# A mode, like gadmin in healthscript
if [ -z "${2+x}" ]; then
    mode=""
else
    mode="_mode_$2"
fi

# one command, reduces total load time
if [ -z "${CHECKPATHS_DEBUG+x}" ]; then
    debugoutroot=/dev/null
else
    debugoutroot=/tmp/checkpaths.out
fi

source $(dirname "$0")/functions.sh

# note: don't use '2>&1' or '&>' for stderr redirection in STATCMD, because it doesn't work for tcsh (>& works both bash and tcsh)
STATCMD="/usr/libexec/slurm/prolog/checkpaths_stat.sh"
STAT_CACHE="/var/tmp/checkpaths.cache.ts"
CACHE_THRESHOLD=20
CACHED_USERS=10

# 30 seconds timeout for the checkpath_stat commands
TIMEOUT=30

# must be lower than 256
ECSTART=200
# order is not important
NAMES=(HOME DATA SCRATCH INSTITUTE_LOCAL SCRATCH_DELCATTY)

# Test user non-cached
id "${userid}" >& /dev/null
ec=$?
echo "test id ${userid} exitcode ${ec}"  >> ${debugoutroot} 2>&1
if [ $ec -ne 0 ]; then
    set_drain "User $userid does not exist"
    exit 1  # if the user does not exist, the job should be pending, regardless
fi

touchfile "${STAT_CACHE}"

# All operations after this cache test are considered slow/expensive
#
# Even when empty, this has to be fine
# The cache only holds last $cacheduser users
cache_ts=$(/bin/grep "$userid" $STAT_CACHE 2>/dev/null | /bin/cut -f1 -d ' ') || 0
now=$(date +%s)
if [ $((cache_ts)) -gt $((now - CACHE_THRESHOLD)) ]; then
    echo "cacheok ${userid}" >> ${debugoutroot} 2>&1
    # use cached ok data
    exit 0
fi

if ! checkpaths_bypass gpfs; then
    # Add basic gpfs check
    if [ -f /var/mmfs/gen/mmsdrfs ]; then
        # we expect a mounted gpfs filessystem
        # probably some scratch filesystem
        gpfss=$(mount -t gpfs 2>/dev/null | wc -l)
        if [ "$gpfss" -eq 0 ]; then
            set_drain "checkpaths failed gpfs${mode} for user ${userid}"
            exit 2  # exit code > 1 ensures the job will be requeued
        fi
    fi
fi

# FIXME: verify codes
function errormsg () {
    if [ "$1" -eq 124 ]; then
        echo "timeout $TIMEOUT"
    else
        # index -1 etc are supported, so make sure the index is  > 0
        if [ "$1" -ge $ECSTART ]; then
            echo "${NAMES[$1 - $ECSTART]}"
        else
            echo "ec $1"
        fi
    fi
}

function dostat () {
    local cmd ec
    cmd="$STATCMD $ECSTART ${NAMES[*]}"
    timeout $TIMEOUT su "$userid" -c "$cmd" >> $debugoutroot 2>&1
    ec=$?
    echo "$STATCMD $1 exitcode $ec user $userid"  >> $debugoutroot 2>&1
    return $ec
}

STAT_DELAYS=(5 30 90)
STAT_EVENTS=(1st 2nd 3rd)
STAT_OK=false

for ((i=0; i < ${#STAT_DELAYS[@]}; ++i));
do
    if ! dostat "${STAT_EVENTS[i]}"; then
        STAT_EC=$?
        sleep "${STAT_DELAYS[i]}"
    else
        STAT_OK=true
        break
    fi
done

if ! $STAT_OK; then
    set_drain "checkpaths_stat failed with $(errormsg ${STAT_EC})$mode for user ${userid}"
    exit ${STAT_EC}
else
    now=$(date +%s)
    # keep last CACHED_USERS users
    last=$(/usr/bin/tail -"${CACHED_USERS}" "${STAT_CACHE}" | /bin/grep -v "$userid")
    /bin/echo "$last" > "${STAT_CACHE}"
    /bin/echo "$now $userid" >> $STAT_CACHE
fi


if slurm_used_cores; then
    logger "Flushing swap ..."
    # flush dirty memory
    sync
    # drop caches
    echo 3 > /proc/sys/vm/drop_caches
    # cleanup swap
    # assume that swap is properly configured (-a reads /etc/fstab; which is used when booting)
    /sbin/swapoff -a
    /sbin/swapon -a
    # report this
    log "flushmemcache drop_caches swapon swapoff"
else
    logger "Unable to flush cache since job partially uses node"
fi


exit 0

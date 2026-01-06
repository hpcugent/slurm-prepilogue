#!/bin/bash
##
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
##

source "$(dirname "$0")/functions.sh"

DROP_CACHE="/var/tmp/drop_cache.cache.ts"
# 30 min
CACHE_THRESHOLD=1800
ALLOW_CACHE_EXPIRE_FN=/etc/slurm/drop_cache

touchfile "${DROP_CACHE}"

if [ -f "$ALLOW_CACHE_EXPIRE_FN" ] ; then
     source "$ALLOW_CACHE_EXPIRE_FN"
fi

NOW=$(date +%s)
DROP=false
if slurm_used_cores; then
    log "drop_cache slurm_used_cores full node"
    DROP=true
elif ! slurm_job_exists; then
    log "drop_cache no other job exists"
    DROP=true
else
    if [ "${DROP_CACHE_EXPIRE:-0}" -eq 1 ]; then
        cache_ts=$(cat $DROP_CACHE) || 0
        if [ $((cache_ts)) -gt $((NOW - CACHE_THRESHOLD)) ]; then
            log "drop_cache no full node but recently dropped, no action"
        else
            log "drop_cache no full node, dropped too long ago"
            DROP=true
        fi
    fi
fi


if $DROP; then
    # flush dirty memory
    sync
    # drop caches
    echo 3 > /proc/sys/vm/drop_caches
    # cleanup swap
    # assume that swap is properly configured (-a reads /etc/fstab; which is used when booting)
    /sbin/swapoff -a
    /sbin/swapon -a
    # report this
    log "drop_cache drop_caches swapon swapoff"

    if [ -n "$DROP_CACHE_CAT" ]; then
        if cat "$DROP_CACHE_CAT" >& /dev/null; then
            log "drop_cache drop_cache_cat ok"
        else
            set_drain "drop_cache_cat $DROP_CACHE_CAT failed"
        fi
    fi

    /bin/echo "$NOW" > $DROP_CACHE
fi


exit 0

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

HE=/var/tmp/healthscript.error

function debug () {
    local debugfn
    debugfn=${DEBUGLOG:-$DEFAULT_DEBUGLOG}
    if [ "${DEBUG:-0}" -gt 0 ]; then
        if [ ! -f "$debugfn" ]; then
            touch "$debugfn"
            chmod 700 "$debugfn"
        fi
        echo "$@" >> "$debugfn"
    fi
}

# bypass checkpaths
# first argument is name for test
# uppercase for env variables check
# lowercase: gpfs
checkpaths_bypass () {
    local name bypassfn value
    name="$1"

    bypassfn="${CHECKPATHS_BYPASS_PREFIX}${name}"
    if [ -f "$bypassfn" ]; then
        value=$(head -1 "$bypassfn")
        if [ "$value" -eq 1 ]; then
            logger "checkpaths_stat: bypass for name $name"
            return 1
        fi
    fi
}
# Touch file and set 0700
function touchfile () {
    local perm fn="$1"

    perm=$(stat --format='%a %U %G' "$fn" 2>/dev/null)
    if [ "$?" -ne 0 ]; then
        touch "$fn"
    fi
    if [ "$perm" != "700 root root" ]; then
        chown root.root "$fn"
        chmod 0700 "$fn"
    fi
}

function mk_health_error () {
    local name="$1"
    shift

    touchfile "$HE"

    # wait 10 seconds before retrying and limit the number of retries to 12
    lockfile -10 -r 12 $HE.lock || error "Failed to get lock for $HE"
    log "health_error $name $userid $*"  # $userid should exist in the environment where this function is called
    # HE file has format <name> <timestamp> <remainder>
    echo "$name $(date +%s) $userid $*" > "$HE"
    /bin/rm -f "$HE.lock"
}

function log () {
    logger -- "$@"
    debug "$@"
}

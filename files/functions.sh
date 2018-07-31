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
CHECKPATHS_BYPASS_PREFIX=/etc/bypass_checkpaths_

SCONTROL=/usr/bin/scontrol

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
    local name="$1" 
    local bypassfn="${CHECKPATHS_BYPASS_PREFIX}${name}"
    local value

    if [ -f "$bypassfn" ]; then
        value=$(head -1 "$bypassfn")
        if [ "$value" -eq 1 ]; then
            logger "checkpaths_stat: bypass for name $name"
            return 0
        fi
    fi

    return 1
}

function log () {
    logger -- "$@"
    debug "$@"
}

function set_drain () {
    local reason="Prolog failure at job ${SLURM_JOB_ID} on $(date +%s): $1"

    ${SCONTROL} update node=$(hostname) state=DRAIN reason="${reason}"
}

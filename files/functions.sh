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

export HE=/var/tmp/healthscript.error
CHECKPATHS_BYPASS_PREFIX=/etc/bypass_checkpaths_
# clustername based on vsc_config
export CHECKPATHS_CLUSTER=$(/usr/bin/sed -n 's/^cluster_name=//p' /etc/vsc_config.cfg 2>/dev/null)

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

function log () {
    logger -- "$@"
    debug "$@"
}

function set_drain () {
    local reason="Prolog failure at job ${SLURM_JOB_ID} on $(date +%s): $1"
    logger "Draining node: $reason"

    ${SCONTROL} update node=$(hostname) state=DRAIN reason="${reason}"
}

function slurm_used_cores () {
    if [ -z ${SLURM_ACTUAL_NODE_CPUS+x} ]; then
        return 1
    fi
    if [ -z ${SLURM_JOB_NODE_CPUS+x} ]; then
        return 1
    fi

    if [ ${SLURM_ACTUAL_NODE_CPUS} -eq ${SLURM_JOB_NODE_CPUS} ]; then
        return 0
    else
        return 1
    fi
}

function slurm_job_exists () {
    # derive existence of slurm jobs indirectly

    # if private tempdir is configured, check for existing binddirs in /dev/shm
    #    (cleaned after reboot)
    local base=/dev/shm/slurm
    if grep "base=$base" /etc/slurm/plugstack.conf >& /dev/null; then
        # seems like spank runs before prolog. so we do expetc to find 1 here
        #    but there's no harm if there isn't any
        local shms
        shms=$(ls $base.* 2> /dev/null | wc -l)
        if [ "$shms" -lt 2 ]; then
            # no jobs, return fail
            return 1
        fi
    fi

    # when in doubt, return 0 (i.e. yes/success)
    return 0
}

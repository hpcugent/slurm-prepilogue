#!/bin/bash
# #
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

# Make a map of the arguments
# First argument is exitcode offset
# Remaining arguments are names, with matching with exitcodes
# Associative array (bash4)
ecstart=$1
shift
declare -A error_map
for name in "$@"; do
    error_map+=( [$name]=$((ecstart++)) )
done

source $(dirname "$0")/functions.sh
logger "checkpaths_stat for job ${SLURM_JOBID}: loading vsc profile"

# Source the VSC_ variables
# This potentially touches some paths for VO-related discovery
unset VSCPROFILELOADED
source /etc/profile.d/vsc.sh

logger "checkpaths_stat for job ${SLURM_JOBID}: loaded vsc profile"

function mystat {
    local name="$1"
    local vscname="VSC_$name"
    local path=${!vscname}
    local cmd

    if checkpaths_bypass "$name"; then
        return 0
    fi

    if [ "$name" == 'INSTITUTE_LOCAL' ]; then
        if [ "$VSC_INSTITUTE_CLUSTER" == 'dodrio' ]; then
            path="/dodrio/apps"
        else
            path="/apps/$path"
        fi
    fi

    if [ -z "${2}" ]; then
        cmd="stat"
    else
        cmd="ls"
    fi

    logger "checkpaths_stat for job ${SLURM_JOBID}: running /usr/bin/$cmd $path"
    errout=$(/usr/bin/$cmd "$path" 2>&1)
    if [ $? -ne 0 ]; then
        # Fallback to 1; must fail
        ec=${error_map[$name]:-1}

        if [ \( "$name" == 'HOME' -o "$name" == "DATA" \) -a "$VSC_INSTITUTE_CLUSTER" == 'dodrio' ]; then
            fail=false
            msg_level='WARN'
        else
            fail=true
            msg_level='ERROR'
        fi

        msg="$USER Failed to stat $path ec $ec out $(echo "$errout" | tr '\n' ' ')"
        logger "checkpaths_stat for job ${SLURM_JOBID}: $msg_level $msg"
        echo "$msg"
        if $fail; then
            exit "$ec"
        fi
    fi
    logger "checkpaths_stat for job ${SLURM_JOBID}: /usr/bin/$cmd $path ok"
}

mystat HOME

mystat DATA

mystat SCRATCH

# cannot use stat, as it does not trigger automount if apps is a separate mountpoint
# we don not expect that many files in the apps dir anyway, so ls is ok
mystat INSTITUTE_LOCAL 1


# Site local and other tests
uid=$(id -u)
if [ "$uid" -gt 60000 ]; then
    # Only for non-system users
    if [ "$VSC_INSTITUTE" == "gent" ] && [ "$VSC_INSTITUTE_CLUSTER" != 'dodrio' ]; then
        mystat SCRATCH_KYUKON
    fi
fi

exit 0

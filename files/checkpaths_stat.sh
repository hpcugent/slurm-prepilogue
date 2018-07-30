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


# Source the VSC_ variables
# This potentially touches some paths for VO-related discovery
unset VSCPROFILELOADED
. /etc/profile.d/vsc.sh

source `dirname $0`/functions.sh

function mystat {
    local name vscname path cmd
    name=$1
    vscname="VSC_$name"
    path=${!vscname}

    checkpaths_bypass "$name"
    if [ $? -eq 1 ]; then
        return 0
    fi

    if [ $name == 'INSTITUTE_LOCAL' ]; then
        path="/apps/$path"
    fi

    if [ -z "$2" ]; then
        cmd="stat"
    else
        cmd="ls"
    fi

    errout=$(/usr/bin/$cmd $path 2>&1 )
    if [ $? -ne 0 ]; then
        # Fallback to 1; must fail
        ec=${error_map[$name]:-1}

        msg="$USER Failed to stat $path ec $ec out $(echo "$errout" | tr '\n' ' ')"
        logger "checkpaths_stat: ERROR $msg"
        echo $msg
        exit $ec
    fi
}

mystat HOME

# Brussels does not have a $VSC_DATA
if [ "$VSC_INSTITUTE" != "brussel" ]; then
    mystat DATA
fi

mystat SCRATCH

# can't use stat, as it does not trigger automount if apps is a separate mountpoint
# we don not expect that many files in the apps dir anyway, so ls is ok
mystat INSTITUTE_LOCAL 1


# Site local and other tests
uid=`id -u`
if [ $uid -gt 60000 ]; then
    # Only for non-system users
    if [ "$VSC_INSTITUTE" == "gent" ]; then
        if [ "$VSC_INSTITUTE_CLUSTER" != "muk" ]; then
            mystat SCRATCH_KYUKON
        fi
    fi
fi

exit 0

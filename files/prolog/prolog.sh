#!/usr/bin/bash
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

HERE=$(dirname $0)

PROLOG_SCRIPT_TIMEOUT=900
PROLOG_CONF=/etc/slurm/prolog.conf

if [ -e ${PROLOG_CONF} ]
then
    . $PROLOG_CONF
fi

if [ -z "${PROLOG_SCRIPTS}" ]
then
    PROLOG_SCRIPTS="checkpaths.sh nrpe_checks.sh nvidia-memtest.sh drop_cache.sh"
fi

source $(dirname "$0")/functions.sh

for check in ${PROLOG_SCRIPTS}; do
    timeout ${PROLOG_SCRIPT_TIMEOUT} $HERE/$check
    ec=$?
    if [ $ec -eq 124 ]; then
        set_drain "$check timeout"
        # actually fail the prolog, so the job doesn't start here
        exit 124
    elif [ $ec -gt 0 ]; then
        # don't set drain message: the individual scripts should set a more
        # detailed drain message, which we would overwrite otherwise
        exit $ec
    fi
done

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

PROLOG_CONF=/etc/slurm/prolog.conf

if [ -e ${PROLOG_CONF} ]
then
    . $PROLOG_CONF
fi

if [ -z "${PROLOG_SCRIPTS}" ]
then
    PROLOG_SCRIPTS="checkpaths.sh nrpe_checks.sh mps_prolog.sh nvidia-memtest.sh drop_cache.sh"
fi

for check in ${PROLOG_SCRIPTS}; do
    $HERE/$check
    ec=$?
    if [ $ec -gt 0 ]; then
        exit $ec
    fi
done

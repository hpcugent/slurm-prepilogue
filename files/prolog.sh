#!/bin/bash
# #
# Copyright 2018-2021 Ghent University
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

for check in checkpaths.sh mps_prolog.sh; do
    $HERE/$check
    ec=$?
    if [ $ec -gt 0 ]; then
        exit $ec
    fi
done

# Configure PMIx direct connection mode
# SLURM_PMIX_DIRECT_CONN: enables direct connection with TCP
# - normally enabled by default (otherwise it's very bad because communication falls back to out-of-band mode)
# - should work with most network setups as it only needs TCP
# SLURM_PMIX_DIRECT_CONN_UCX: enables direct connection with UCX
# - enabled by default if Slurm is built with PMIx and UCX
# - IB only works with the mlx5 driver with rdma-core (supported since MOFED 4.7+ or MOFED 5.1+)
# SLURM_PMIX_DIRECT_CONN_EARLY: enables UCX earlier in the communication setup
# - disabled by default

# Disable SLURM_PMIX_DIRECT_CONN_UCX on mlx4 as it is not supported
# This is only needed for our ivybridge nodes with ConnectX-3, can be removed whenever those are thrown away
[ -d "/sys/module/mlx4_core" ] && PMIX_UCX="0" || PMIX_UCX="1"

export SLURM_PMIX_DIRECT_CONN="1"
export SLURM_PMIX_DIRECT_CONN_UCX="$PMIX_UCX"
export SLURM_PMIX_DIRECT_CONN_EARLY="$PMIX_UCX"

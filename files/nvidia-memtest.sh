#!/usr/bin/bash

if [ -z "${SLURM_JOB_GPUS}" ]
then
        # no GPU set - skip test
        exit 0
fi

source $(dirname "$0")/functions.sh

log "$0 checking GPUs for job ${SLURM_JOBID} (${SLURM_JOB_GPUS})"

GPU_MEMTEST=/usr/libexec/slurm/prolog/memtestG80

log "$0 SLURM_JOB_GPUS: $SLURM_JOB_GPUS"
id=0
IFS=,
for realid in $SLURM_JOB_GPUS
do
        log "running memtest for job ${SLURM_JOBID} on gpu $id (real id $realid)"
        $GPU_MEMTEST --gpu $id 1 1 > /dev/null 2>&1
        ec=$?
        if [ $ec -ne 0 ]; then
            # we don't log the id for the GPU, because it might be different
            # than the id seen outside the prolog
            log "$0 GPU memtest for job ${SLURM_JOBID} failed"
            set_drain "GPU memtest for job ${SLURM_JOBID} failed"
            exit 2
        fi
        log "GPU $id memtest for job ${SLURM_JOBID} OK"
        let id=id+1
done

exit 0

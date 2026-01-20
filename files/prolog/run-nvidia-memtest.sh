#!/usr/bin/bash
#
# Wrapper script to run the nvidia memtest outside the prolog
# It runs the memtest on the first COUNT GPUs, where COUNT is
# - the number specified as a command line argument
# - NVIDIA_GPU_COUNT as defined in prolog.conf
# - the number of NVIDIA GPUs found on the system
#   (this might exclude broken GPUs)

GPU_MEMTEST=/usr/libexec/slurm/prolog/memtestG80
PROLOG_CONF=/etc/slurm/prolog.conf

if [ -e ${PROLOG_CONF} ]
then
    . $PROLOG_CONF
fi

res=0

COUNT="$1"

if [ -z "$COUNT" ]
then
    # from prolog.conf
    COUNT="$NVIDIA_GPU_COUNT"
fi

if [ -z "$COUNT" ]
then
    COUNT=$(nvidia-smi -L | wc -l)
    echo "GPU count not specified, running memtest on all $COUNT found GPUs"
fi


for ((id = 0; id < COUNT; id++))
do
    $GPU_MEMTEST --gpu $id 1 1 > /dev/null 2>&1
    ec=$?
    if [ $ec -ne 0 ]; then
        echo "GPU memtest on GPU $id FAILED"
        res=1
    else
        echo "GPU memtest on GPU $id OK"
    fi
done

exit $res

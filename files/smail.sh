#! /bin/bash

# Copyright 2015 Princeton University Research Computing

# Input should look like this for an end record:
# $1: '-s' (the subject argument keyword)
# $2: The subject itself
# $3: The To: email address.
#
# The subject should look like this for an start record:
# SLURM Job_id=323 Name=ddt_clone Began, Queued time 00:00:01
#
# The subject should look like this for an end record:
# SLURM Job_id=327 Name=ddt_clone Ended, Run time 00:05:01, COMPLETED, ExitCode 0
# SLURM Job_id=328 Name=ddt_clone Failed, Run time 00:05:01, FAILED, ExitCode 127
# SLURM Job_id=342 Name=ddt_clone Ended, Run time 00:00:33, CANCELLED, ExitCode 0
# Not sure what to do about PENDING state resulting from a requeue request.
# Doing a seff on it for now:
# SLURM Job_id=326 Name=ddt_clone Failed, Run time 00:00:41, PENDING, ExitCode 0
#
# These end records are the only types of messages to process. They have 4 (rather
# than 2) comma-delimited arguments, of which ending status is the 3rd.
# Just pass through notifications without an ending status.

if [[ "$SLURM_JOB_COMMENT" =~ mail:: ]]; then
    # switch to html mail mode
    exec $(dirname -- "${BASH_SOURCE[0]}")/smail.html.sh
fi

MAIL=/bin/mail
export MAILRC=/var/spool/slurm/.mailrc

IFS=","
array=($2)
IFS=" "

# Get the ClusterName
ClusterName=$(scontrol show config | grep ClusterName | awk '{printf("[%s]", $3)}')
subject="$ClusterName $2"
recipient=$3

# If we decide later to seff based on specific status codes,
# we can test against $status.
status=$(echo "${array[2]}" | tr -d ' ')
if [ -n "$status" ]; then
    sarray=(${array[0]})
    IFS="="
    if [ "${sarray[1]}" = "Array" ]; then
        sarray=(${sarray[3]})
    else
        sarray=(${sarray[1]})
    fi
    IFS=" "
    jobid="${sarray[1]}"
    # Fork a child so sleep is asynchronous.
    {
        sleep 60
        slurm_jobinfo "$jobid" | $MAIL -s "$subject" "$recipient"
    } &
else
    $MAIL -s "$subject" "$recipient"
fi

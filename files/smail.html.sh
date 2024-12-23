#!/usr/bin/bash

if [[ "$SLURM_CLUSTER_NAME" =~ "dodrio" ]]; then
    ood_endpoint=tier1
else
    ood_endpoint=login
fi
ood_file_url="https://${ood_endpoint}.hpc.ugent.be/pun/sys/dashboard/files/fs/"

# Mail has same environment variables as pro/epiloge, and some extras

# quick
job_json="$(scontrol show job "$SLURM_JOB_ID" --json | jq -c '.jobs[0]')"


# slow-ish, needed for extra usage reporting
#acct_json="$(sacct --job "$SLURM_JOB_ID" --json | jq -c '.jobs[0]')"

if [[ "$SLURM_JOB_COMMENT" =~ mail:: ]]; then
    # everything between mail:: and ::mail is assumed json
    comment_json="${SLURM_JOB_COMMENT##*mail::}"
    comment_json="$(echo "${comment_json%%::mail*}" | jq -c .)"
else
    comment_json='{}'
fi



function from_comment {
     echo "$comment_json" | jq -r "$1"
}

function from_job_json {
    echo "$job_json" | jq -r "$1"
}


rows=()

function add_row {
    value="$2"
    if [ -n "$value" ] && [ "$value" != "null" ]; then
        if [ "$3" == "ood" ]; then
	        value="<a href=\"$ood_file_url$value\">$value</a>"
        elif [ "$3" == "timestamp" ]; then
            value="$(date -d @"$value" '+%Y-%m-%dT%H:%M:%S')"
        fi
        rows+=("<tr><td>$1</td><td>$value</td></tr>")
    fi
}

function add_env {
    value="${!2}"
    add_row "$1" "$value" "$3"
}


function add_json {
    # for things not in variables
    value=$(from_job_json "$2")
    add_row "$1" "$value" "$3"
}

#function add_acct {
#    # for things not in variables
#    value=$(echo "$acct_json" | jq -r "$2")
#    add_row "$1" "$value" "$3"
#}

function add_comment {
    value=$(from_comment "$2")
    add_row "$1" "$value" "$3"
}

# Nothing is added when empty

add_env Id SLURM_JOB_ID
add_env Name SLURM_JOB_NAME

add_env "Main array job" SLURM_ARRAY_JOB_ID
add_env "Array index" SLURM_ARRAY_TASK_ID

add_env User SLURM_JOB_USER
add_env Cluster SLURM_CLUSTER_NAME
add_env Partition SLURM_JOB_PARTITION
add_env Account SLURM_JOB_ACCOUNT

# Only one of these 2 is not empty
add_json Nodes .nodes
add_json "Scheduled nodes" .scheduled_nodes

add_json Cores .job_resources.cpus
add_json GPUs '[.jobs[0].gres_detail[] | select(startswith("gpu:")) | sub("gpu:(?<cnt>[0-9]+).*"; "\(.cnt)") | tonumber ] | add'

add_env "Mail type" SLURM_JOB_MAIL_TYPE

# The so-called BASESTATE
add_env State SLURM_JOB_STATE
add_json "All states" '.job_state | join(",")'


add_json Submit ".submit_time.number" timestamp
add_json Start ".start_time.number" timestamp
add_json End  ".end_time.number" timestamp

add_json "Working directory" .current_working_directory ood
add_json "Stdout" ".stdout" ood
add_json "Stderr" ".stderr" ood
add_comment "OOD session" .ood_session ood
add_comment "Result" .result ood


# BEGIN only
add_env "Queued time" SLURM_JOB_QEUEUED_TIME
# END/FAILED/REQUEUE
add_env "Running time" SLURM_JOB_RUN_TIME

# Needs to come from accounting data
#add_row "Reserved walltime"   : 01:00:0.0
#add_row "Used walltime"       : 00:09:43.0
#add_row "Used CPU time"       : 00:08:21.164
#add_row "% User (Computation)": 97.58
#add_row "% System (I/O)"      :  2.42
#add_row "Mem reserved"        : 13612M
#add_row "Max Mem used"        : 2.02G (node4013.donphan.os)
#add_row "Max Disk Write"      : 655.36K (node4013.donphan.os)
#add_row "Max Disk Read"       : 60.87M (node4013.donphan.os)

mail_user="$(from_job_json .mail_user)"

jobinfo=$(from_comment .info)
if [ -z "$jobninfo" ]; then
    jobinfo="$SLURM_JOB_NAME"
fi

# the ${,,} forces lowercase
subject="[$SLURM_CLUSTER_NAME] Job $SLURM_JOB_ID $jobinfo ${SLURM_JOB_MAIL_TYPE,,}."

html=$(cat<<EOF
<!DOCTYPE html>
<html>
  <body>
      <table>${rows[*]}</table>
  </body>
</html>
EOF
)

# The mail sending part

export MAILRC=/var/spool/slurm/.mailrc


if [ -f /usr/bin/s-nail ]; then
    MAIL=/usr/bin/s-nail
    mime=(-M text/html)
else
    # No consistent way to do this, depending on version can pass e.g. via -a option or inject header like
    # (
	#    echo -e "Content-Type: text/html\n"
    #    echo "$html"
    # ) | $MAIL -s "$subject" "$mail_user"

    # Anyway,  we assume s-nail is installed (the el9 default)
    MAIL=/bin/mail
    mime=()
fi

echo "$html" | $MAIL -s "$subject" "${mime[@]}" "$mail_user"

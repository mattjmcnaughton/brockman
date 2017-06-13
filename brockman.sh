#!/bin/bash
#
# A lightweight utility for reporting on background unix processes.
# See https://github.com/mattjmcnaughton/brockman for more info.

# `BROCKMAN_DIR` stores the alert/error log, in addition to potential additional configuration.
# If there is already an existing environment variable when we run `brockman.sh`, that value will
# be used. If not, it defaults to `~/.brockman`. Passing in the specialized `$BROCKMAN_DIR`
# is necessary for testing.
readonly BROCKMAN_DIR="${BROCKMAN_DIR:?~/.brockman}"
readonly BROCKMAN_ALERT_LOG="$BROCKMAN_DIR/alert.log"
readonly BROCKMAN_ERROR_LOG="$BROCKMAN_DIR/error.log"

# Only certain options can be passed to the view command (representing the `{alert,error}.log`).
readonly ALLOWED_VIEW_TYPES="^(alert|error)$"

# The report processes which its file to a temporary file while running. Then, if the report command
# exits in failure, we copy the error file over to `$BROCKMAN_ERROR_LOG`. We want to use a different
# temporary error file each time.
REPORT_PROCESSES_ERROR_FILE=

# Clean up the report processes error file. If we create `$REPORT_PROCESSES_ERROR_FILE`, set
# a trap to clean it up on exit.
brockman::remove_report_processes_error_file() {
    if [ -n "$REPORT_PROCESSES_ERROR_FILE" ] && [ -f "$REPORT_PROCESSES_ERROR_FILE" ]
    then
        rm $REPORT_PROCESSES_ERROR_FILE
    fi
}

# Run the processes passed as an argument and report errors appropriately.
brockman::report() {
    bash -c "$@ > $REPORT_PROCESSES_ERROR_FILE 2>&1"
    exit_code=$?

    if [ "$exit_code" -ne 0 ]
    then
        echo "$(date)" | tee $BROCKMAN_ALERT_LOG $BROCKMAN_ERROR_LOG >/dev/null

        cat << EOF >> $BROCKMAN_ALERT_LOG
Command $@ failed with exit code $exit_code: See $BROCKMAN_ERROR_LOG for further
details.
EOF

        cat $REPORT_PROCESSES_ERROR_FILE >> $BROCKMAN_ERROR_LOG
    fi
}

# Return success if brockman has unreported errors and fail if not.
brockman::failure() {
    if [ ! -s "$BROCKMAN_ALERT_LOG" ]
    then
        exit 1
    fi
}

# Output the alert/error logs. Takes `[alert|error]` as an argument.
brockman::view() {
    if [ "$1" = "alert" ]
    then
        cat $BROCKMAN_ALERT_LOG
    elif [ "$1" = "error" ]
    then
        cat $BROCKMAN_ERROR_LOG
    fi
}

# Clear the alert/error logs. `resolve` will delete all data.
brockman::resolve() {
    log_files=(
        $BROCKMAN_ALERT_LOG
        $BROCKMAN_ERROR_LOG
    )

    for log_file in ${log_files[@]}
    do
        rm $log_file
        touch $log_file
    done
}

# If any of the log files/directories don't exist, create them.
brockman::setup() {
    if [ ! -d "$BROCKMAN_DIR" ]
    then
        mkdir $BROCKMAN_DIR
    fi

    touch $BROCKMAN_ALERT_LOG
    touch $BROCKMAN_ERROR_LOG
}

brockman::setup

case $1 in
report)
    if [ $# -lt 2 ]
    then
        echo "Must pass a command to \`report\`." >&2
        exit 2
    fi

    REPORT_PROCESSES_ERROR_FILE=$(mktemp)

    # To prevent leaking of any tmp files.
    trap 'brockman::remove_report_processes_error_file' EXIT

    shift
    brockman::report "$@"
    ;;
failure)
    brockman::failure
    ;;
view)
    if [ $# -ne 2 ] && ! echo "$2" | grep -q "$ALLOWED_VIEW_TYPES"
    then
        echo "Must pass a $ALLOWED_VIEW_TYPES to \`view\`." >&2
        exit 2
    fi

    brockman::view "$2"
    ;;
resolve)
    brockman::resolve
    ;;
*)
    echo "Invalid args." >&2
    exit 2
    ;;
esac

# If here, then command executed successfully.
exit 0

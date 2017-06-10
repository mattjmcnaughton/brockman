#!/bin/bash
#
# A lightweight utility for reporting on background unix processes.
# See https://github.com/mattjmcnaughton/brockman for more info.

BROCKMAN_DIR="${BROCKMAN_DIR:?~/.brockman}"
BROCKMAN_ALERT_LOG="$BROCKMAN_DIR/alert.log"
BROCKMAN_ERROR_LOG="$BROCKMAN_DIR/error.log"

tmp_error_file=

remove_tmp_err_file() {
    if [ -n "$tmp_error_file" ] && [ -f "$tmp_error_file" ]
    then
        rm $tmp_error_file
    fi
}

report() {
    bash -c "$@ > $tmp_error_file 2>&1"
    exit_code=$?

    if [ "$exit_code" -ne 0 ]
    then
        echo "$(date)" | tee $BROCKMAN_ALERT_LOG $BROCKMAN_ERROR_LOG >/dev/null

        cat << EOF >> $BROCKMAN_ALERT_LOG
Command $@ failed with exit code $exit_code: See $BROCKMAN_ERROR_LOG for further
details.
EOF

        cat $tmp_error_file >> $BROCKMAN_ERROR_LOG
    fi
}

failure() {
    if [ ! -s "$BROCKMAN_ALERT_LOG" ]
    then
        exit 1
    fi
}

view() {
    if [ "$1" = "alert" ]
    then
        cat $BROCKMAN_ALERT_LOG
    elif [ "$1" = "error" ]
    then
        cat $BROCKMAN_ERROR_LOG
    fi
}

resolve() {
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

ALLOWED_VIEW_TYPES="^(alert|error)$"

case $1 in
--report)
    if [ $# -lt 2 ]
    then
        echo "Must pass a command to \`--report\`." >&2
        exit 2
    fi

    tmp_error_file=$(mktemp)
    trap 'remove_tmp_err_file' EXIT

    shift
    report "$@"
    ;;
--failure)
    failure
    ;;
--view)
    if [ $# -ne 2 ] && ! echo "$2" | grep -q "$ALLOWED_VIEW_TYPES"
    then
        echo "Must pass a $ALLOWED_VIEW_TYPES to \`--view\`." >&2
        exit 2
    fi

    view "$2"
    ;;
--resolve)
    resolve
    ;;
*)
    echo "Invalid args." >&2
    exit 2
    ;;
esac

exit 0

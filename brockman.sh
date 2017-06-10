#!/bin/bash
#
# A lightweight utility for reporting on background unix processes.
# See https://github.com/mattjmcnaughton/brockman for more info.

set -e

BROCKMAN_DIR="${BROCKMAN_DIR:?~/.brockman}"
BROCKMAN_ALERT_LOG="$BROCKMAN_DIR/alert.log"
BROCKMAN_ERROR_LOG="$BROCKMAN_DIR/error.log"

report() {
    exit 0
}

failure() {
    if [ ! -s "$BROCKMAN_ALERT_LOG" ]
    then
        exit 1
    fi
}

view() {
    exit 0
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
    if [ $# -ne 2 ]
    then
        echo "Must pass a command to \`--report\`." >&2
        exit 2
    fi

    report "$2"
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

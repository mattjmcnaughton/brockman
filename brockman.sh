#!/bin/bash
#
# A lightweight utility for reporting on background unix processes.
# See https://github.com/mattjmcnaughton/brockman for more info.

set -e

BROCKMAN_DIR=~/.brockman
BROCKMAN_ALERT_LOG="$BROCKMAN_DIR/alert.log"
BROCKMAN_ERROR_LOG="$BROCKMAN_DIR/error.log"

report() {
    exit 0
}

failure() {
    exit 0
}

view() {
    exit 0
}

resolve() {
    exit 0
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

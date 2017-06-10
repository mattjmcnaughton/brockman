#!/bin/bash
#
# Unit tests for `brockman.sh`. Run with `bash test/test_brockman.sh`.

PATH_TO_BROCKMAN="$(dirname $0)/../brockman.sh"

# Handle restoring the brockman dir to the environment variable existing before
# this script ran.
restore_initial_state() {
    rm -r $BROCKMAN_DIR
    export BROCKMAN_DIR=""
}

# Assign `BROCKMAN_DIR` to a random tmp directory so
# we don't delete any state on the user's machine when testing.
export BROCKMAN_DIR="$(mktemp -d)"

BROCKMAN_ALERT_LOG="$BROCKMAN_DIR/alert.log"
BROCKMAN_ERROR_LOG="$BROCKMAN_DIR/error.log"

if [ ! -d "$BROCKMAN_DIR" ]
then
    mkdir $BROCKMAN_DIR
fi

# Test passing invalid options to `brockman.sh` fails.
test_option_processing() {
    invalid_commands=(
        --report
        --fake-argument
        --view
        --view\ INVALID_TYPE
    )

    for invalid_command in ${invalid_commands[@]}
    do
        $PATH_TO_BROCKMAN $invalid_command 2>/dev/null
        status_code=$?

        if [ "$status_code" -eq 0 ]
        then
            echo "Invalid command $invalid_command did not cause error" >&2
            exit 1
        fi
    done
}

test_resolve() {
    # Set up test info in $BROCKMAN_ALERT_LOG and $BROCKMAN_ERROR_LOG
    echo 'error' | tee $BROCKMAN_ALERT_LOG $BROCKMAN_ERROR_LOG >/dev/null

    $PATH_TO_BROCKMAN --resolve

    log_files=(
        $BROCKMAN_ALERT_LOG
        $BROCKMAN_ERROR_LOG
    )

    for log_file in ${log_files[@]}
    do
        if [ -s "$log_file" ]
        then
            echo "--resolve should have cleared out: $log_file."
            exit 1
        fi
    done
}

trap 'restore_initial_state' EXIT

test_option_processing
test_resolve

exit 0

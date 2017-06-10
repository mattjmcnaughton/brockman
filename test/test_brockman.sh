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

setup() {
    if [ ! -d "$BROCKMAN_DIR" ]
    then
        mkdir $BROCKMAN_DIR
    fi

    touch $BROCKMAN_ALERT_LOG
    touch $BROCKMAN_ERROR_LOG
}

log_error() {
    echo "$1" >&2
    exit 1
}

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
            log_error "Invalid command $invalid_command did not cause error"
        fi
    done
}

test_failure() {
    $PATH_TO_BROCKMAN --failure
    status_code=$?

    if [ "$status_code" -ne 1 ]
    then
        log_error "--failure should fail when there is no error."
    fi

    echo 'error' > $BROCKMAN_ALERT_LOG

    $PATH_TO_BROCKMAN --failure
    status_code=$?

    if [ "$status_code" -ne 0 ]
    then
        log_error "--failure should succeed when errors exist."
    fi
}

test_view() {
    alert_message='alert_log'
    error_message='error_log'

    echo "$alert_message" > $BROCKMAN_ALERT_LOG
    echo "$error_message" > $BROCKMAN_ERROR_LOG

    alert_view=$($PATH_TO_BROCKMAN --view alert)
    error_view=$($PATH_TO_BROCKMAN --view error)

    if [ "$alert_view" != "$alert_message" ]
    then
        log_error "--view alert should display $alert_message"
    fi

    if [ "$error_view" != "$error_message" ]
    then
        log_error "--view error should display $error_message"
    fi
}

test_resolve() {
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
            log_error "--resolve should have cleared out: $log_file."
        fi
    done
}

trap 'restore_initial_state' EXIT

setup
test_option_processing
test_failure
test_view
test_resolve

exit 0

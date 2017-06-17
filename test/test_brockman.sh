#!/bin/bash
#
# Unit tests for `brockman.sh`. Run with `bash test/test_brockman.sh`.

# Assume the directory structure has the `test_brockman.sh` one directory below `brockman.sh`.
PATH_TO_BROCKMAN="$(dirname $0)/../brockman.sh"

# Assign `BROCKMAN_DIR` to a random tmp directory so
# we don't delete any state on the user's machine when testing.
export BROCKMAN_DIR="$(mktemp -d)"

BROCKMAN_ALERT_LOG="$BROCKMAN_DIR/alert.log"
BROCKMAN_ERROR_LOG="$BROCKMAN_DIR/error.log"

# Handle restoring the brockman dir to the environment variable existing before
# this script ran.
test_brockman::restore_initial_state() {
    rm -r $BROCKMAN_DIR
    export BROCKMAN_DIR=""
}

# Some of the tests assume the existence of brockman alert/error files before we run `brockman.sh`.
# So replica the `brockman.sh` set up step.
#
# @TODO(mattjmcnaughton) Use the setup method from `brockman.sh`.
test_brockman::setup() {
    if [ ! -d "$BROCKMAN_DIR" ]
    then
        mkdir $BROCKMAN_DIR
    fi

    touch $BROCKMAN_ALERT_LOG
    touch $BROCKMAN_ERROR_LOG
}

test_brockman::log_error() {
    echo "$1" >&2
    exit 1
}

test_brockman::test_option_processing() {
    invalid_commands=(
        report
        fake-argument
        view
        view\ INVALID_TYPE
    )

    for invalid_command in ${invalid_commands[@]}
    do
        $PATH_TO_BROCKMAN $invalid_command 2>/dev/null
        exit_code=$?

        if [ "$exit_code" -eq 0 ]
        then
            test_brockman::log_error "Invalid command $invalid_command did not cause error"
        fi
    done
}

test_brockman::test_report_success() {
    success_script="$BROCKMAN_DIR/success_script.sh"
    cat << EOF > $success_script
#!/bin/bash
echo \$1
exit 0
EOF

    chmod u+x $success_script

    $PATH_TO_BROCKMAN report "$success_script ARGUMENT"

    if $PATH_TO_BROCKMAN view alert | grep -q "$success_script"
    then
        test_brockman::log_error "report should not log alert containing $success_script"
    fi

    if $PATH_TO_BROCKMAN view error | grep -q "ARGUMENT"
    then
        test_brockman::log_error "report should not log error containing ARGUMENT"
    fi

    $PATH_TO_BROCKMAN resolve
}

test_brockman::test_report_failure() {
    error_script="$BROCKMAN_DIR/error_script.sh"
    cat << EOF > $error_script
#!/bin/bash
echo \$1 >&2
exit 1
EOF

    chmod u+x $error_script

    $PATH_TO_BROCKMAN report "$error_script ARGUMENT"

    if ! $PATH_TO_BROCKMAN view alert | grep -q "$error_script"
    then
        test_brockman::log_error "report should log alert containing $error_script"
    fi

    if ! $PATH_TO_BROCKMAN view error | grep -q "ARGUMENT"
    then
        test_brockman::log_error "report should log error containing ARGUMENT"
    fi

    $PATH_TO_BROCKMAN resolve
}

test_brockman::test_failure() {
    $PATH_TO_BROCKMAN failure
    exit_code=$?

    if [ "$exit_code" -ne 1 ]
    then
        test_brockman::log_error "failure should fail when there is no error."
    fi

    echo 'error' > $BROCKMAN_ALERT_LOG

    $PATH_TO_BROCKMAN failure
    exit_code=$?

    if [ "$exit_code" -ne 0 ]
    then
        test_brockman::log_error "failure should succeed when errors exist."
    fi

    $PATH_TO_BROCKMAN resolve
}

test_brockman::test_view() {
    alert_message='alert_log'
    error_message='error_log'

    echo "$alert_message" > $BROCKMAN_ALERT_LOG
    echo "$error_message" > $BROCKMAN_ERROR_LOG

    alert_view=$($PATH_TO_BROCKMAN view alert)
    error_view=$($PATH_TO_BROCKMAN view error)

    if [ "$alert_view" != "$alert_message" ]
    then
        test_brockman::log_error "view alert should display $alert_message"
    fi

    if [ "$error_view" != "$error_message" ]
    then
        test_brockman::log_error "view error should display $error_message"
    fi

    $PATH_TO_BROCKMAN resolve
}

test_brockman::test_resolve() {
    echo 'error' | tee $BROCKMAN_ALERT_LOG $BROCKMAN_ERROR_LOG >/dev/null

    $PATH_TO_BROCKMAN resolve

    log_files=(
        $BROCKMAN_ALERT_LOG
        $BROCKMAN_ERROR_LOG
    )

    for log_file in ${log_files[@]}
    do
        if [ -s "$log_file" ]
        then
            test_brockman::log_error "resolve should have cleared out: $log_file."
        fi
    done
}

trap 'test_brockman::restore_initial_state' EXIT

test_brockman::setup
test_brockman::test_option_processing
test_brockman::test_report_success
test_brockman::test_report_failure
test_brockman::test_failure
test_brockman::test_view
test_brockman::test_resolve

exit 0

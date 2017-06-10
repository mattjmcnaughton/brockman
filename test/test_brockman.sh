#!/bin/bash
#
# Unit tests for `brockman.sh`. Run with `bash test/test_brockman.sh`.

PATH_TO_BROCKMAN="$(dirname $0)/../brockman.sh"

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

test_option_processing

exit 0

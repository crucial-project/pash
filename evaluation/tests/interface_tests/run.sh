#!/bin/bash

export PASH_TOP=${PASH_TOP:-$(git rev-parse --show-toplevel --show-superproject-working-tree)}

## TODO: Make the compiler work too.
bash="bash"
pash="$PASH_TOP/pa.sh --dry_run_compiler"

output_dir="$PASH_TOP/evaluation/tests/interface_tests/output"
mkdir -p "$output_dir"

run_test()
{
    local test=$1
    echo -n "Running $test..."
    $test "bash" > "$output_dir/$test.bash.out"
    test_bash_ec=$?
    $test "$pash" > "$output_dir/$test.pash.out"
    test_pash_ec=$?
    diff "$output_dir/$test.bash.out" "$output_dir/$test.pash.out"
    test_diff_ec=$?

    if [ $test_diff_ec -ne 0 ]; then
        echo -n "$test output mismatch"
    fi
    if [ $test_bash_ec -ne $test_pash_ec ]; then
        echo -n "$test exit code mismatch"
    fi
    if [ $test_diff_ec -ne 0 ] || [ $test_bash_ec -ne $test_pash_ec ]; then
        echo '   FAIL'
        return 1
    else
        echo '   OK'
        return 0
    fi
}

test1()
{
    local shell=$1
    $shell echo_args.sh 1 2 3
}

## Tests -c
test2()
{
    local shell=$1
    $shell -c 'echo $2 $1' pash 2 3
}

## Tests -c and the assignment to $0
test3()
{
    local shell=$1
    $shell -c 'echo $0 $2 $1' pash 2 3
}

run_test test1
run_test test2
run_test test3
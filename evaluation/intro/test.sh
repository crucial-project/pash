#!/usr/bin/env bash

export PASH_TOP=${PASH_TOP:-$(git rev-parse --show-toplevel --show-superproject-working-tree)}

## TODO: Make the compiler work too.
bash="bash"
pash="$PASH_TOP/pa.sh -w 2"

output_dir="$PASH_TOP/evaluation/intro/output"
mkdir -p "$output_dir"

( cd "$PASH_TOP/evaluation/intro/input"; ./setup.sh ) 

run_test()
{
    local test=$1

    echo -n "Running $test..."
    $bash "$test" > "$output_dir/$test.bash.out"
    test_bash_ec=$?
    $pash "$test" > "$output_dir/$test.pash.out"
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
        echo "are not identical" > $output_dir/${test}_distr*.time
        echo '   FAIL'
        return 1
    else
        echo "are identical" > $output_dir/${test}_distr*.time
        echo '   OK'
        return 0
    fi
}

run_test "demo-spell.sh"
run_test "hello-world.sh"

echo "Below follow the identical outputs:"
grep --files-with-match "are identical" "$output_dir"/*_distr*.time

echo "Below follow the non-identical outputs:"
grep -L "are identical" "$output_dir"/*_distr*.time

TOTAL_TESTS=$(ls -la "$output_dir"/*_distr*.time | wc -l)
PASSED_TESTS=$(grep --files-with-match "are identical" "$output_dir"/*_distr*.time | wc -l)
echo "Summary: ${PASSED_TESTS}/${TOTAL_TESTS} tests passed."

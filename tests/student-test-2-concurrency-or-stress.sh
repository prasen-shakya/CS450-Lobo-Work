#!/bin/sh
# Student Test 2: Concurrency or Stress
# This test must cover either concurrent worker behavior or a larger/stress
# workload that exercises repeated queue and worker activity.


# Check that many jobs finish and multiple workers run at once.

OUT=tests/output/student-test-2.out
mkdir -p tests/output

{
    i=1
    while [ "$i" -le 40 ]; do
        printf 'job%s 20\n' "$i"
        i=$((i + 1))
    done
} | ./lobo_work.x -w 4 -q 2 >"$OUT" 2>&1
program_status=$?

failed=0
[ "$program_status" -eq 0 ] || failed=1
grep -q 'submitted: 40;' "$OUT" || failed=1
grep -q 'accepted: 40;' "$OUT" || failed=1
grep -q 'rejected: 0;' "$OUT" || failed=1
grep -q 'completed: 40;' "$OUT" || failed=1

max_active=$(sed -n 's/.*max_active: \([0-9][0-9]*\);.*/\1/p' "$OUT")
if [ -z "$max_active" ] || [ "$max_active" -lt 2 ] || [ "$max_active" -gt 4 ]; then
    failed=1
fi

if [ "$failed" -eq 0 ]; then
    echo "PASS student-test-2"
else
    echo "FAIL student-test-2"
    cat "$OUT"
    exit 1
fi
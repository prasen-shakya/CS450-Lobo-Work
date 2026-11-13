# Student Test 3: Shutdown, Parsing, or Statistics
# This test must cover one of: clean shutdown, workload parsing/error handling,
# or the required statistics and invariants.

#!/bin/sh
# Test malformed input after several valid jobs.
# Earlier jobs must finish; input after the bad line must not be submitted.

OUT=tests/output/student-test-3.out
mkdir -p tests/output

printf 'first 30\nsecond 30\nthird 30\nfourth 30\nmalformed\nafter 0\n' |
    ./lobo_work.x -w 2 -q 1 >"$OUT" 2>&1
program_status=$?

if [ "$program_status" -ne 0 ] &&
   grep -q 'error: malformed workload line' "$OUT" &&
   grep -q 'submitted: 4;' "$OUT" &&
   grep -q 'accepted: 4;' "$OUT" &&
   grep -q 'rejected: 0;' "$OUT" &&
   grep -q 'completed: 4;' "$OUT" &&
   [ "$(grep -c '^submitted:' "$OUT")" -eq 1 ]; then
    echo "PASS student-test-3"
else
    echo "FAIL student-test-3"
    cat "$OUT"
    exit 1
fi
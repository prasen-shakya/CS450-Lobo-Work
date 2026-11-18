# Extra Credit Test: Comments and Blank Lines
# This test checks input handling that isn't covered by the given tests:
# the parser must skip comment lines and blank lines and
# only the remaining valid jobs should appear in the final stats.

TEST=student-test-4-comments-blanks
SAMPLES=$(realpath "$(dirname "$0")")/../sample_jobs
OUTPUT=$(realpath "$(dirname "$0")")/output
OUT=$OUTPUT/$TEST.out
LOG=$OUTPUT/$TEST.log
PROGRAM=${PROGRAM:-./lobo_work.x}

test "tests" = "$(basename "$(dirname "$(realpath "$0")")")" || { echo "FAIL: $0 not in 'tests'"; exit 1; }
test -x "$PROGRAM" || { echo "FAIL: $PROGRAM must exist and be executable"; exit 2; }
test -r "$SAMPLES/comments-and-blanks.txt" || { echo "FAIL: $SAMPLES/comments-and-blanks.txt must exist"; exit 2; }
mkdir -p "$OUTPUT"
rm -f "$OUT"

cat >"$LOG" <<'EOF'

Description:
------------
This test checks that the sample job 'comments-and-blanks.txt' is parsed
correctly. The file has 3 valid jobs (alpha, beta, gamma) mixed with comment
lines and blank lines. None of the given tests check that comments and
blanks are actually skipped, they only check basic jobs.

How we check it:
The 3 valid jobs are the only ones that should show up in the stats, so
submitted, accepted, and completed must all be 3, nothing gets rejected,
max_active is between 1 and 2 and the exit status is zero.

Command:
--------
./lobo_work.x --workers 2 --queue 4 < sample_jobs/comments-and-blanks.txt
EOF

"$PROGRAM" --workers 2 --queue 4 <"$SAMPLES/comments-and-blanks.txt" >"$OUT" 2>&1
STATUS=$?

grep -q 'submitted: 3;' "$OUT" || STATUS=1
grep -q 'accepted: 3;' "$OUT" || STATUS=1
grep -q 'rejected: 0;' "$OUT" || STATUS=1
grep -q 'completed: 3;' "$OUT" || STATUS=1
grep -q 'workers: 2;' "$OUT" || STATUS=1
grep -q 'queue_capacity: 4;' "$OUT" || STATUS=1
MAX_ACTIVE=$(sed -n 's/.*max_active: \([0-9][0-9]*\).*/\1/p' "$OUT")
test -n "$MAX_ACTIVE" || STATUS=1
test "$MAX_ACTIVE" -ge 1 2>/dev/null || STATUS=1
test "$MAX_ACTIVE" -le 2 2>/dev/null || STATUS=1

if test "$STATUS" -eq 0; then
   echo "PASS $TEST"
else
   echo "FAIL $TEST"
   exit 1
fi

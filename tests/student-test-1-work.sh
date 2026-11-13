# Student Test 1: Work
# This test must cover basic work behavior, such as valid job submission,
# execution, completion, or required work statistics.

TEST=student-test-1-work
SAMPLES=$(realpath "$(dirname "$0")")/../sample_jobs
OUTPUT=$(realpath "$(dirname "$0")")/output
OUT=$OUTPUT/$TEST.out
LOG=$OUTPUT/$TEST.log
PROGRAM=${PROGRAM:-./lobo_work.x}

test "tests" = "$(basename "$(dirname "$(realpath "$0")")")" || { echo "FAIL: $0 not in 'tests'"; exit 1; }
test -x "$PROGRAM" || { echo "FAIL: $PROGRAM must exist and be executable"; exit 2; }
test -r "$SAMPLES/short.txt" || { echo "FAIL: $SAMPLES/short.txt must exist"; exit 2; }
mkdir -p "$OUTPUT"
rm -f "$OUT"

cat >"$LOG" <<'EOF'

Description:
------------
This test checks that the sample job 'short.txt' is fully executed.
Its different from test-2-basic-work.sh because it checks a job with actual duration, 
and test-2-basic-work.sh checks with a placeholder with 0 duration jobs.

How we check full execution:
Every job is accepted, no job is rejected, every job completes, max_active
is at least one, the exit status is zero and the elapsed wall time is long
enough to show the sleeps actually ran.

Command:
--------
./lobo_work.x --workers 2 --queue 4 < sample_jobs/short.txt
EOF

START=$(date +%s%N)
"$PROGRAM" --workers 2 --queue 4 <"$SAMPLES/short.txt" >"$OUT" 2>&1
STATUS=$?
END=$(date +%s%N)
ELAPSED_MS=$(( (END - START) / 1000000 ))

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
test "$ELAPSED_MS" -ge 70 2>/dev/null || STATUS=1

if test "$STATUS" -eq 0; then
   echo "PASS $TEST"
else
   echo "FAIL $TEST"
   exit 1
fi

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

# Lobo Work Design Document

Complete this document with your team. Keep the prompts and write responses
replacing each `@TODO` line.

## Team members:

- Prasen Shakya
- Luis Cortes

## What each person contributed:

- Prasen contributed by implementing the mutex locks, conditional variables, and implementing the worker function.

- Luis: I worked on student-test-1; It was inspired by test-2-basic-work.sh but instead of using
placeholder jobs with no duration we tested on the 'short.xt' sample job given. I also made sure that our code ran on blue,
and that all the tests behaved as expected.

## How you coordinated changes and testing:

@TODO

## Module and interface changes

Identify which provided files your team left unchanged. Then identify each
file your team changed and briefly explain why.
If you changed a provided file or public interface, explain the change and its
effect on the rest of the program. Otherwise, state that the provided interfaces
were preserved.

**Files we didn't change:** 
- `work_pool.h`
- `work_queue.c`
- `work_queue.h`
- `job_parse.c`
- `job_parse.h` 
- `lobo_work.h`
- `Makefile`

**Changed files:**

- `work_pool.c`: We modified `work_pool.c` because this was where we did our pool implementation.
  The changes we made to `work_pool.c` do not affect the rest of the program
  other than making the pool actually run jobs on multiple worker threads.
- `lobo_work.c`: We modified `lobo_work.c` so that the `worker_count` argument
  gets passed into `lobo_work_pool_create` and printed in the final stats line.
- `tests/`: We added `student-test-1-work.sh`,
  `student-test-2-concurrency-or-stress.sh`, and
  `student-test-3-shutdown-or-parsing-or-statistics.sh`.

**Public interface:**

We did not cahnge any of the public interfaces.

## Worker-pool synchronization

List every mutex and condition variable in your implementation. Use the
appropriate format below for each synchronization object, using these notes:

* use the exact variable or field name from your code.
* for "Location," give the source or header filename and, when applicable, the containing struct type and field name.
* for thread-role fields, use only: "main thread", "worker threads", or "both".
* for a condition variable, describe the predicate checked in the corresponding while loop.

For a mutex:

```text
Mutex variable name or struct field:
Location:
Initialized by (thread-role):
Destroyed by (thread-role):
Threads that lock it (thread-role):
Threads that unlock it (thread-role):
Shared state protected:
```

For a condition variable:

```text
Condition-variable name or struct field:
Location:
Initialized by (thread-role):
Destroyed by (thread-role):
Threads that wait on it (thread-role):
Threads that signal or broadcast it (thread-role):
Associated mutex:
Condition being waited for:
```

### Mutexes

```text
Mutex variable name or struct field: lock
Location: work_pool.c, struct LoboWorkPool, field lock
Initialized by (thread-role): main thread
Destroyed by (thread-role): main thread
Threads that lock it (thread-role): both
Threads that unlock it (thread-role): both
Shared state protected: queue, stats, active, and closed.
```

### Condition Variables

```text
Condition-variable name or struct field: not_empty
Location: work_pool.c, struct LoboWorkPool, field not_empty
Initialized by (thread-role): main thread
Destroyed by (thread-role): main thread
Threads that wait on it (thread-role): worker threads
Threads that signal or broadcast it (thread-role): main thread
Associated mutex: lock
Condition being waited for: the queue has at least one job or the pool is closed.
```

```text
Condition-variable name or struct field: not_full
Location: work_pool.c, struct LoboWorkPool, field not_full
Initialized by (thread-role): main thread
Destroyed by (thread-role): main thread
Threads that wait on it (thread-role): main thread
Threads that signal or broadcast it (thread-role): worker threads
Associated mutex: lock
Condition being waited for: the queue has room for another job or the pool is closed.
```

## Worker-loop summary

Describe the worker loop in a few paragraphs or a short fenced pseudocode block.
Address only the important implementation decisions:

* what a worker does when no job is available;
* how it obtains a job safely;
* when it releases the mutex;
* when it calls the job runner;
* when it updates active and completed counts; and
* how it exits during pool closure, including what tells it that no more jobs
  will arrive and whether it finishes queued jobs before returning.

Do not restate the assignment requirements. Describe how your code implements
them.

For our implemenation, we have each worker running an infinite loop that starts
by locking `pool->lock`. While there isn't a job available and the pool isn't closed,
the worker waits on the `not_empty` condition. The wait also releases the mutex while
the worker sleeps.

Once the worker gets the lock again and the queue is non-empty, the worker then
calls `lobo_work_queue_pop` to copy the oldest job into a local variable, and then
the worker signals `not_full` so that a blocked producer can then reuse the freed slot.
The worker then increments `active`, and updates `stats.max_active` if `active`
is greater than the current `stats.max_active` value. After this the worker releases the mutex
and the job runner is called so that other workers and the main thread can acquire the lock while the job runs.

When the job runner finishes, the worker relocks the mutex, decrements `active`,
increments `stats.completed`, and then unlocks. Afterward, it then loops again for the next job.

The worker exits when the wait loop ends with `queue.count == 0`, which
means the queue is empty and `closed` is set. `lobo_work_pool_close` sets
`closed` and broadcasts `not_empty`, so idle workers wake up and return. A
worker that wakes while jobs remain in the queue keeps popping and running them,
so every accepted job finishes before the workers return. `close` then joins
all worker threads, so no job is lost or still running when it returns.

```text
loop:
    lock
    while queue empty and not closed: wait(not_empty)
    if queue empty:
        unlock; return
    pop job; signal(not_full)
    active++; max_active = max(max_active, active)
    unlock
    runner(job)                # no lock held
    lock; active--; completed++; unlock
```

## Testing

Describe the three student tests you wrote, using this format:

```text
Test:
Purpose:
Command:
Expected result:
Observed result:
Failure this test would reveal:
```

For each test, explain why it adds meaningful coverage beyond the supplied tests.

### `student-test-1-work.sh`

Test: student-test-1-work.sh
Purpose: Check that the sample job 'short.txt' is fully executed with jobs that
have real durations (not zero).
Command: ./lobo_work.x --workers 2 --queue 4 < sample_jobs/short.txt
Expected result: Exit status is zero. Final stats line shows submitted: 3,
accepted: 3, rejected: 0, completed: 3, workers: 2, queue_capacity: 4, and
max_active between 1 and 2. Elapsed wall time is at least 70 ms so we know
the sleeps actually ran.
Observed result: PASS. All three jobs are accepted and completed, no jobs are
rejected, max_active stays within 1 and 2, the run takes long enough to
confirm the jobs actually slept.
Failure this test would reveal: Jobs being skipped or dropped, max_active
exceeding the worker count, the pool returning before work finishes, the
runner being short circuited so the sleeps never actually happen.

### `student-test-2-concurrency-or-stress.sh`

@TODO

### `student-test-3-shutdown-or-parsing-or-statistics.sh`

@TODO

## Additional design decisions

Use this section only for decisions that are not already specified by the
assignment or represented in the synchronization inventory.

@TODO

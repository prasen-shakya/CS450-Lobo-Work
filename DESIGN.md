# Lobo Work Design Document

Complete this document with your team. Keep the prompts and write responses
replacing each `@TODO` line.

## Team members:

- Prasen Shakya
- Luis Cortes


## What each person contributed:

- Prasen contributed by implementing the mutex locks, conditional variables, and implementing the worker function.

- Luis: I worked on student-test-1. It was inspired by test-2-basic-work.sh but instead of using
placeholder jobs with no duration we tested on the 'short.xt' sample job given. I also made sure that our code ran on blue, and that all the tests behaved as expected.


## How you coordinated changes and testing:

Most of the coordination happened through a group chat we made. We took turns reviewing and adding in our contributions to the project. Some coodination also happened before/after class. We also made sure to go over each other's work to double check the updates being made. We used GitHub to keep track of all the changes being made and to make sure we were working on the most up to date version of the project. When it came to testing that was mainly done locally as we implemented each test. Once the test were confirmed to be working locally we also tested them on blue.


## Module and interface changes

Identify which provided files your team left unchanged. Then identify each
file your team changed and briefly explain why.
If you changed a provided file or public interface, explain the change and its
effect on the rest of the program. Otherwise, state that the provided interfaces
were preserved.

student-test-1-work.sh: Added implementation for student-test-1.
student-test-4-comments-blanks.sh: Added implementation for student-test-4 (extra credit).


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

Each worker loops forever until the pool closes. On every iteration it grabs
the pool lock and waits on not_empty as long as the queue is empty and the
pool is still open. If the worker wakes up and the queue is still empty, that
means the pool has been closed so it drops the lock and returns.

If its not close it pops the oldest job off the queue, signals not_full so any
blocked submitter can make progress, then it increases 'active'. Then it releases 
the lock before calling the runner which is what actually lets multiple workers overlap. 
When the runner returns, the worker reacquires the lock just long enough to decrement 
active and increase completed, then heads back to the top of the loop.

Closing is what actually stops the loop. lobo_work_pool_close sets 'closed' and
broadcasts both condition variables so any worker waiting on not_empty
wakes up. Workers that still see jobs on the queue keep draining them, they
only exit once the queue is actually empty. After the broadcast, 'close'
joins every worker so by the time it returns every accepted job has run.



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
Purpose: Check that the sample job 'short.txt' is fully executed with jobs that have real durations (not zero).
Command: ./lobo_work.x --workers 2 --queue 4 < sample_jobs/short.txt
Expected result: Exit status is zero. Final stats line shows submitted: 3, accepted: 3, rejected: 0, completed: 3, workers: 2, queue_capacity: 4, and max_active between 1 and 2. Elapsed wall time is at least 70 ms so we know the sleeps actually ran.
Observed result: PASS. All three jobs are accepted and completed, no jobs are rejected, max_active stays within 1 and 2, the run takes long enough to confirm the jobs actually slept.
Failure this test would reveal: Jobs being skipped or dropped, max_active exceeding the worker count, the pool returning before work finishes, the runner being short circuited so the sleeps never actually happen.


### `student-test-2-concurrency-or-stress.sh`

@TODO


### `student-test-3-shutdown-or-parsing-or-statistics.sh`

@TODO


### `student-test-4-comments-blanks.sh` (extra credit)

Test: student-test-4-comments-blanks.sh
Purpose: Check that the sample job 'comments-and-blanks.txt' is parsed correctly, with comment lines and blank lines skipped so that only the valid jobs end up in the final stats.
Command: ./lobo_work.x --workers 2 --queue 4 < sample_jobs/comments-and-blanks.txt
Expected result: Exit status is zero. Final stats line shows submitted: 3, accepted: 3, rejected: 0, completed: 3, workers: 2, queue_capacity: 4, and max_active between 1 and 2.
Observed result: PASS. Only the 3 valid jobs (alpha, beta, gamma) show up in the stats, nothing is rejected, and max_active stays within 1 and 2.
Failure this test would reveal: The parser counting comment or blank lines as jobs, inflating submitted/accepted, or the pool mishandling input that has gaps between valid lines.


## Additional design decisions

N/A

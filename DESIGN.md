# Lobo Work Design Document

Complete this document with your team. Keep the prompts and write responses
replacing each `@TODO` line.

## Team members:

- Prasen Shakya
- Luis Cortes


## What each person contributed:

- Prasen contributed by implementing the mutex locks, conditional variables, and implementing the worker function.

- Luis: Worked on student-test-1; Inspired by test-2-basic-work.sh but instead of using
placeholder jobs with no duration we tested on the 'short.xt' sample job given.
Will work on student-test-2 once test-1 is confirmed to be working on blue.


## How you coordinated changes and testing:

@TODO


## Module and interface changes

Identify which provided files your team left unchanged. Then identify each
file your team changed and briefly explain why.
If you changed a provided file or public interface, explain the change and its
effect on the rest of the program. Otherwise, state that the provided interfaces
were preserved.

@TODO


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

@TODO


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

@TODO


### `student-test-2-concurrency-or-stress.sh`

@TODO


### `student-test-3-shutdown-or-parsing-or-statistics.sh`

@TODO


## Additional design decisions

Use this section only for decisions that are not already specified by the
assignment or represented in the synchronization inventory.

@TODO

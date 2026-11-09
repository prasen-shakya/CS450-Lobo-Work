/**
 * @file work_pool.c
 * @brief Serial pool module used by the student skeleton.
 *
 * This version deliberately has no threads and no locking. It introduces the
 * queue and the pool interface before concurrency is added.
 */

#define _POSIX_C_SOURCE 200809L

#include "work_pool.h"

#include "work_queue.h"

#include "pthread.h"

#include <stdlib.h>

struct LoboWorkPool {
   int worker_count;
   LoboWorkRunner runner;
   LoboWorkQueue queue;
   LoboWorkPoolStats stats;

   pthread_mutex_t lock;
   pthread_t *threads;
};

LoboWorkPool *
lobo_work_pool_create(int worker_count, int queue_capacity,
                      LoboWorkRunner runner)
{
   LoboWorkPool *pool = calloc(1, sizeof *pool);
   if (pool == NULL || !lobo_work_queue_init(&pool->queue,
                                              (size_t) queue_capacity)) {
      free(pool);
      return NULL;
   }

   pthread_mutex_init(&pool->lock, NULL);
   pool->threads = malloc(sizeof(pthread_t) * worker_count);


   pool->worker_count = worker_count;
   pool->runner = runner;
   return pool;
}

int
lobo_work_pool_add(LoboWorkPool *pool, const LoboWorkJob *job)
{
   if (!lobo_work_queue_try_add(&pool->queue, job)) {
      pool->stats.rejected++;
      return 0;
   }

   pool->stats.accepted++;
   return 1;
}

void
lobo_work_pool_close(LoboWorkPool *pool)
{
   LoboWorkJob job;

   while (lobo_work_queue_pop(&pool->queue, &job)) {
      pool->stats.max_active = 1;
      pool->runner(&job);
      pool->stats.completed++;
   }
}

void
lobo_work_pool_get_stats(LoboWorkPool *pool,
                         LoboWorkPoolStats *stats)
{
   *stats = pool->stats;
}

void
lobo_work_pool_destroy(LoboWorkPool *pool)
{
   lobo_work_queue_destroy(&pool->queue);
   free(pool);
}

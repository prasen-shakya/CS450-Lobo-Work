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

#include <pthread.h>
#include <stdio.h>

#include <stdlib.h>

struct LoboWorkPool {
   int worker_count;
   LoboWorkRunner runner;
   LoboWorkQueue queue;
   LoboWorkPoolStats stats;

   pthread_mutex_t lock;
   pthread_t *threads;

   pthread_cond_t not_empty;
   pthread_cond_t not_full;
   
   int closed;
   unsigned long active;
};

static void *worker(void *arg) {
   LoboWorkPool *pool = arg;

   while (1) {
      LoboWorkJob curJob;

      pthread_mutex_lock(&pool->lock);

      while (pool->queue.count == 0 && !pool->closed) {
         pthread_cond_wait(&pool->not_empty, &pool->lock);
      }

      // Queue is closed
      if (pool->queue.count == 0) {
         pthread_mutex_unlock(&pool->lock);
         return NULL;
      }

      if (!lobo_work_queue_pop(&pool->queue, &curJob)) {
         pthread_mutex_unlock(&pool->lock);
         fprintf(stderr, "Queue pop failed");
         return NULL;
      }

      // Signal that a slot opened up
      pthread_cond_signal(&pool->not_full);

      pool->active++;
      if (pool->active > pool->stats.max_active) {
         pool->stats.max_active = pool->active;
      }

      pthread_mutex_unlock(&pool->lock);

      // Run the job
      pool->runner(&curJob);

      pthread_mutex_lock(&pool->lock);
      pool->active--;
      pool->stats.completed++;
      pthread_mutex_unlock(&pool->lock);
   }
}

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
   pthread_cond_init(&pool -> not_empty, NULL);
   pthread_cond_init(&pool->not_full, NULL);

   pool->threads = malloc(sizeof(pthread_t) * worker_count);

   pool->worker_count = worker_count;
   pool->runner = runner;

   for (int i = 0; i < worker_count; i++) {
      if (pthread_create(&pool->threads[i], NULL, worker, pool) != 0) {
            fprintf(stderr, "pthread_create failed\n");
            return NULL;
        }
   }

   return pool;
}

int
lobo_work_pool_add(LoboWorkPool *pool, const LoboWorkJob *job)
{
   pthread_mutex_lock(&pool -> lock);

   while (!lobo_work_queue_try_add(&pool->queue, job)) {
      pthread_cond_wait(&pool -> not_full, &pool -> lock);
   }

   pthread_cond_signal(&pool->not_empty);

   pool->stats.accepted++;
   pthread_mutex_unlock(&pool -> lock);
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

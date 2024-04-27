/*

A simple table for jobs that uses partitioning to reduce contention and
bloat. There is partitioning at three levels: job type, status, and time.

At the first level, the idea is to have all jobs in seemingly one table,
but use different partitions underneath for different queues. We assign
types to jobs and use partitions to decide which types go into which queue.
In this example, we use one queue for two types, and a separate queue
for the third type. With multiple queues it's possible to use
multiple job pullers without locking. And even if locking is used,
there will be less contention on a per queue basis.

The nature of the job types will determine how many queues to have and
how to group job types. For example: if you expect to have a lot of a
particular job type, you don't want its processing to impact other
job types. In that case, you may want to put it into a separate queue.

Another example, some job types may take much longer, or you may otherwise
want to control execution concurrency. Same thing, put them into a
separate queue.

In Postgres 17, merging and splitting of partitions will be supported,
which will make it easier to use queues. You could start with one
default queue and split as needed.

If multiple pullers per queue are needed, the table could be further
sharded using hash partitioning. A system of leases can be devised to
have pullers compete and that all shards are handled in the event of
puller failure.

This design assumes queues are kept in memory, which provides a lot
of flexibility over scheduling of individual jobs. In fairness in
multi-tenant environments is required, consider using shuffle sharding.

At the second level, we use partitioning to reduce bloat, with (for
example) daily partitions that can be quickly dropped rather than
vacuumed. However, we still use further two partitioning levels in order
to support a dead letter queue, the idea being that we sometimes may want
to keep dead jobs for longer. Thus the latter two partition layers
are per job status, then run_at timestamp.

 */

CREATE TYPE job_status AS ENUM ('active', 'completed', 'dead');

CREATE TYPE job_type AS ENUM ('type1', 'type2', 'type3');

CREATE TABLE tenant_jobs
(
    tenant_id  UUID        NULL REFERENCES tenants (tenant_id) ON DELETE CASCADE,

    job_id     UUID        NOT NULL DEFAULT gen_chrono_uuid(),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    run_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    type       JOB_TYPE    NOT NULL,

    input      JSONB       NOT NULL,

    status     JOB_STATUS  NOT NULL DEFAULT 'active',

    PRIMARY KEY (tenant_id, job_id, type, status, run_at)

) PARTITION BY LIST (type);

-- This index is designed to support finding new jobs added since
-- a timestamp. The idea is that, at startup, one puller will load
-- all jobs, then periodically poll for new jobs.
CREATE INDEX ON tenant_jobs (created_at) WHERE status = 'active';

ALTER TABLE tenant_jobs
    ENABLE ROW LEVEL SECURITY;

CREATE
    POLICY tenant_jobs_template_policy ON tenant_jobs
    USING (tenant_id = rls_get_tenant_id()::UUID);

GRANT ALL
    ON tenant_jobs TO acme_role_tenant;


-- Partitions.

-- TODO If we're partitioning on run_at, we should add a CHECK that the value is
--      in the future. We won't necessarily have partitions in the past. We'll also
--      need to create sufficient future partitions depending on how far in the
--      future run_at can be.

CREATE TABLE tenant_jobs_default PARTITION OF tenant_jobs FOR VALUES IN ('type1','type2') PARTITION BY LIST (status);

CREATE TABLE tenant_jobs_queue2 PARTITION OF tenant_jobs FOR VALUES IN ('type3') PARTITION BY LIST (status);

CREATE TABLE tenant_jobs_default_undead PARTITION OF tenant_jobs_default FOR VALUES IN ('active', 'completed') PARTITION BY RANGE (run_at);

CREATE TABLE tenant_jobs_default_dead PARTITION OF tenant_jobs_default FOR VALUES IN ('dead');

CREATE TABLE tenant_jobs_queue2_undead PARTITION OF tenant_jobs_queue2 FOR VALUES IN ('active', 'completed') PARTITION BY RANGE (run_at);

CREATE TABLE tenant_jobs_queue2_dead PARTITION OF tenant_jobs_queue2 FOR VALUES IN ('dead');

-- TODO Do we need to configure row-level security on the partitions?

/*
-- Use partman to create future partitions. This assumes we'll
-- create jobs that run only up to 30 days in the future.

SELECT partman.create_parent(p_parent_table => 'main.tenant_jobs_default_undead',
                             p_control => 'run_at',
                             p_interval => '1 day',
                             p_premake => '33'
       );

SELECT partman.create_parent(p_parent_table => 'main.tenant_jobs_queue3_undead',
                             p_control => 'run_at',
                             p_interval => '1 day',
                             p_premake => '33'
       );

*/
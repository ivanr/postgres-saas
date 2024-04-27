/*

A simple jobs table that uses partitioning to reduce contention and
bloat. There is partitioning at three levels: job type, status, and time.

At the first level, the idea is to have one jobs table, but different
partitions for different job types, or queues. In this example, one
partition is used for two queues, and there is a separate partition
for the third queue. With multiple queues it's possible to use
multiple job pullers without locking. And even if locking is used,
there will be less contention on a per queue basis.

If multiple pullers per queue are needed, the table could be further
sharded. A system of leases can be devised to let pullers compete
and that all shards are handled in the event of puller failure.

In Postgres 17, merging and splitting of partitions will be supported,
which will make it easier to use queues. You could start with one
default queue and split as needed.

We want to use the next level of partitioning to reduce bloat, with
daily (for example) partitions that can be quickly dropped. However,
we still use further two partitioning levels in order to support
a dead letter queue, the idea being that we sometimes may want to
keep dead jobs for longer. Thus the latter two partition layers
are per job status, then run_at timestamp.

 */

CREATE TYPE job_status AS ENUM ('active', 'completed', 'dead');

CREATE TYPE job_type AS ENUM ('queue1', 'queue2', 'queue3');

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

CREATE TABLE tenant_jobs_default PARTITION OF tenant_jobs FOR VALUES IN ('queue1','queue2') PARTITION BY LIST (status);

CREATE TABLE tenant_jobs_queue3 PARTITION OF tenant_jobs FOR VALUES IN ('queue3') PARTITION BY LIST (status);

CREATE TABLE tenant_jobs_default_undead PARTITION OF tenant_jobs_default FOR VALUES IN ('active', 'completed') PARTITION BY RANGE (run_at);

CREATE TABLE tenant_jobs_default_dead PARTITION OF tenant_jobs_default FOR VALUES IN ('dead');

CREATE TABLE tenant_jobs_queue3_undead PARTITION OF tenant_jobs_queue3 FOR VALUES IN ('active', 'completed') PARTITION BY RANGE (run_at);

CREATE TABLE tenant_jobs_queue3_dead PARTITION OF tenant_jobs_queue3 FOR VALUES IN ('dead');

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
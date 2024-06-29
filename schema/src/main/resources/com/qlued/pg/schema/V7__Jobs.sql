/*

A simple table for jobs that uses partitioning to reduce contention and
bloat. There is partitioning at two levels: job type and then time.

At the first level, the idea is to have all jobs in seemingly one table,
but use different partitions underneath for different queues. We assign
types to jobs and use partitions to decide which types go into which queue.

It's possible to put multiple job types into a single queue if desired.
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

At the second level, we use time-based partitioning to reduce bloat, with (for
example) daily partitions that can be quickly dropped rather than
vacuumed.

 */

CREATE TYPE job_status AS ENUM ('active', 'completed', 'failed');

CREATE TYPE job_type AS ENUM ('type1', 'type2');

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

CREATE INDEX tenant_jobs_status_run_at ON tenant_jobs (status, run_at);

ALTER TABLE tenant_jobs
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_jobs_template_policy ON tenant_jobs
    USING ((SELECT rls_get_tenant_id()::UUID) = tenant_id);

GRANT ALL
    ON tenant_jobs TO acme_role_tenant;


-- Partitions.

CREATE TABLE tenant_jobs_type1 PARTITION OF tenant_jobs FOR VALUES IN ('type1') PARTITION BY RANGE (run_at);

CREATE TABLE tenant_jobs_type2 PARTITION OF tenant_jobs FOR VALUES IN ('type2') PARTITION BY RANGE (run_at);

-- TODO Do we need to configure row-level security on the partitions?


-- Use partman to create future partitions. The limitation of using partman
-- is that we can't schedule job at arbitrary times in the future. If we
-- were to create partitions on demand, we could.

SELECT partman.create_parent(p_parent_table => 'main.tenant_jobs_type1',
                             p_control => 'run_at',
                             p_interval => '15 minute',
                             p_premake => '2'
       );

SELECT partman.create_parent(p_parent_table => 'main.tenant_jobs_type2',
                             p_control => 'run_at',
                             p_interval => '15 minute',
                             p_premake => '2'
       );

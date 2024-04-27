CREATE TYPE job_status AS ENUM ('active', 'completed', 'dead');

CREATE TABLE tenant_jobs
(
    tenant_id  UUID        NULL REFERENCES tenants (tenant_id) ON DELETE CASCADE,

    job_id     UUID        NOT NULL DEFAULT gen_chrono_uuid(),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    run_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    input      JSONB       NOT NULL,

    status     JOB_STATUS  NOT NULL DEFAULT 'active',

    PRIMARY KEY (tenant_id, job_id, status, run_at)

) PARTITION BY LIST (status);

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

CREATE TABLE tenant_jobs_undead PARTITION OF tenant_jobs FOR VALUES IN ('active', 'completed') PARTITION BY RANGE (run_at);

CREATE TABLE tenant_jobs_dead PARTITION OF tenant_jobs FOR VALUES IN ('dead');

-- TODO Do we need to configure row-level security on the partitions?

/*
-- Use partman to create future permissions. This assumes we'll
-- create jobs that run only up to 30 days in the future.
SELECT partman.create_parent(p_parent_table => 'main.tenant_jobs_undead',
                             p_control => 'run_at',
                             p_interval => '1 day',
                             p_premake => '33'
       );
*/
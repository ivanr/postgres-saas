CREATE TYPE job_status AS ENUM ('active', 'completed', 'dead');

CREATE TABLE tenant_jobs
(
    tenant_id  UUID        NULL REFERENCES tenants (tenant_id) ON DELETE CASCADE,

    job_id     UUID        NOT NULL DEFAULT gen_chrono_uuid(),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    run_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    input      JSONB       NOT NULL,

    status     JOB_STATUS  NOT NULL DEFAULT 'active',

    PRIMARY KEY (tenant_id, job_id, status)

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

CREATE TABLE tenant_jobs_undead PARTITION OF tenant_jobs FOR VALUES IN ('active', 'completed');

CREATE TABLE tenant_jobs_dead PARTITION OF tenant_jobs FOR VALUES IN ('dead');

-- TODO Do we need to configure row-level security on the partitions?

CREATE TABLE tenant_work
(
    tenant_id                   UUID NULL REFERENCES tenants (tenant_id) ON DELETE CASCADE,

    work_id                     UUID NOT NULL DEFAULT gen_chrono_uuid(),

    -- When should the next work be attempted.
    schedule_next_run           TIMESTAMPTZ,

    -- Useful when there are many competing jobs and you want
    -- some to run before others. Use a value between 0 and 100
    -- by default so that you can always add some work before
    -- and after others.
    schedule_priority           SMALLINT      DEFAULT 50,

    -- What is the deadline for the work to be completed.
    schedule_next_deadline      TIMESTAMPTZ,

    -- When was the list time the work had completed successfully.
    schedule_last_success       TIMESTAMPTZ,

    -- When was the last failure; cleared on success.
    schedule_last_failure       TIMESTAMPTZ,

    -- Error message associated with the last failure; clear on success.
    schedule_last_error_message TEXT,

    -- Used to detect scheduling changes.
    schedule_last_modified      TIMESTAMPTZ,

    -- TODO You will usually need additional fields here to determine
    --      how to determine the next time after success, how to deal
    --      with failure, and so on.

    -- TODO Job information may be implicit from the table itself. If
    --      it is not, you could have an additional JSONB field to
    --      carry the job information.

    PRIMARY KEY (tenant_id, work_id)
);

-- Useful to fetch due jobs.
CREATE INDEX tenant_work_schedule_next_run ON tenant_work (schedule_next_run);

-- This index can be used to find rows that have
-- been modified since the last fetch. Can be useful
-- for schedules that load all jobs in memory.
CREATE INDEX tenant_work_schedule_last_modified ON tenant_work (schedule_last_modified);

ALTER TABLE tenant_work
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_work_template_policy ON tenant_work
    USING ((SELECT rls_get_tenant_id()::UUID) = tenant_id);

GRANT ALL
    ON tenant_work TO acme_role_tenant;

CREATE TABLE audit_log
(

    entry_id        UUID        NOT NULL DEFAULT gen_chrono_uuid(),

    -- Optional, but required for entries that take place within tenant accounts.
    tenant_id       UUID REFERENCES tenants (tenant_id) ON DELETE CASCADE,

    -- Used to give tenants access to entries. Normally, all tenants have access to
    -- events related to their accounts. However, they may also get access to other
    -- events, for example those related to user accounts that are considered to
    -- belong to them. Row level security operates based on this value.
    authz_tenant_id UUID        NOT NULL REFERENCES tenants (tenant_id) ON DELETE CASCADE,


    -- Principal information.

    -- An easy way to determine principal types:
    --   'A' - anonymous
    --   'S' - system
    --   'U' - user
    principal_type  TEXT        NOT NULL,

    -- Optional, but required for activities carried out by users.
    user_id         UUID REFERENCES users (user_id) ON DELETE RESTRICT,

    -- For use when users act on behalf of an organization, for example, member
    -- of support staff making changes for the tenant.
    proxy_tenant_id UUID REFERENCES tenants (tenant_id) ON DELETE RESTRICT,


    -- Core event metadata.

    timestamp       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Unique transaction/request ID, where applicable. The idea is that
    -- every activity is initiated somewhere and we want to be able to
    -- track an activity to its origin.
    transaction_id  TEXT,

    -- Optional, if there is an IP address associated with this entry.
    remote_addr     INET,

    -- Optional, if there is user session associated with this entry.
    session_id      TEXT,

    -- Optional, if there is a device associated with this entry.
    device_id       TEXT,


    -- Information about the activity itself.

    -- Unique resource identifier. For HTTP events, contains the URL path, including the query string.
    resource        TEXT        NOT NULL,

    -- For example, 'http.get' or 'user.auth.signed_in'.
    activity        TEXT        NOT NULL,

    -- Tracks whether the action was successful, using HTTP status codes.
    status          INTEGER     NOT NULL,

    -- Syslog severities.
    severity        SMALLINT    NOT NULL,


    -- Custom event data. Ideally, each event would have its own schema.

    detail_type     TEXT CHECK ((detail_type IS NULL AND detail IS NULL) OR
                                (detail_type IS NOT NULL AND detail IS NOT NULL)),

    detail          JSONB,


    -- Custom data associated with the event; the idea with attachments
    -- is to keep track of native data in whatever format it is available.

    attachment_type TEXT CHECK ((attachment_type IS NULL AND attachment IS NULL) OR
                                (attachment_type IS NOT NULL AND attachment IS NOT NULL)),

    attachment      BYTEA

) PARTITION BY RANGE (timestamp);

CREATE INDEX ON audit_log (timestamp);

-- Docs https://github.com/pgpartman/pg_partman/blob/master/doc/pg_partman.md#user-content-creation-functions
SELECT partman.create_parent(p_parent_table => 'main.audit_log',
                             p_control => 'timestamp',
                             p_type => 'native',
                             p_interval => 'quarter-hour',
           -- Note: Ensure that the background job, configured using 'pg_partman_bgw.interval'
           --       in postgresql.conf runs frequently enough to create new partitions. In this
           --       repo, the background process runs every minute.
                             p_premake => '6'
           );

UPDATE partman.part_config
SET infinite_time_partitions = true,
    retention                = '1 hour',
    retention_keep_table     = true
WHERE parent_table = 'main.audit_log';

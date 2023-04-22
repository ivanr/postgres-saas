CREATE TABLE audit_log
(

    entry_id        UUID        NOT NULL DEFAULT gen_chrono_uuid(),


    -- Owner information.
    --
    -- Events that take place within tenant accounts are always attached to them. Events that
    -- take place outside are always attached to individual users. If a tenant owns a user
    -- account, then these events are also attached to the tenant, giving them visibility
    -- into the user's activity.

    -- Owning tenant. When a tenant is deleted, all their audit events are deleted.
    owner_tenant_id UUID        NULL REFERENCES tenants (tenant_id) ON DELETE CASCADE,

    -- Owning user.
    owner_user_id   UUID        NULL REFERENCES users (user_id) ON DELETE RESTRICT,

    CONSTRAINT has_owner CHECK ((owner_tenant_id IS NOT NULL) OR (owner_user_id IS NOT NULL)),


    -- Actor information.

    -- An easy way to determine principal types:
    --   'A' - anonymous
    --   'S' - system
    --   'U' - user
    actor_type      CHAR        NOT NULL,

    -- The user that caused this event, where applicable.
    actor_user_id   UUID        NULL REFERENCES users (user_id),

    -- the actor tenant that caused this event, where applicable. This field
    -- is used when users act on behalf an organization, and not in their
    -- individual capacity.
    actor_tenant_id UUID        NULL REFERENCES tenants (tenant_id),

    CONSTRAINT valid_actor_type CHECK (
        actor_type IN ('A', 'S', 'U')
        ),

    CONSTRAINT consistent_actor_type CHECK (
            ((actor_type = 'U') AND (actor_user_id IS NOT NULL)) OR
            ((actor_user_id IS NULL) AND (actor_tenant_id IS NULL))
        ),


    -- Core event metadata.

    timestamp       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- OpenTelemetry trace identifier.
    trace_id        TEXT        NULL,

    -- Optional, if there is an IP address associated with this entry.
    remote_addr     INET        NULL,

    -- Optional, if there is user session associated with this entry.
    session_id      TEXT        NULL,

    -- Optional, if there is a device associated with this entry.
    device_id       TEXT        NULL,

    -- Optional, user agent information.
    user_agent      TEXT        NULL,


    -- Information about the activity itself.

    -- Resource type.
    resource_type   TEXT,

    -- Native resource identifier.
    resource_id     TEXT,

    -- For example, 'http.get' or 'user.auth.signed_in'.
    activity        TEXT        NOT NULL,

    -- Tracks whether the action was successful, using HTTP status codes.
    status          INTEGER     NOT NULL,

    -- Syslog severities.
    -- TODO Enum.
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

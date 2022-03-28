CREATE TABLE audit_log
(

    tenant_id       UUID        NOT NULL,

    event_id        UUID        NOT NULL,

    tenant_user_id  UUID        NOT NULL,

    -- Allowed to be NULL in order to support disconnecting
    -- the tenant-user account from the user, for example
    -- for privacy reasons, whilst retaining a history of
    -- user activity.
    user_id         UUID,

    -- TODO Support system activity.
    -- TODO Support users acting on behalf of someone, for example support staff.
    -- TODO Do we want to support users personal service accounts?

    remote_addr     TEXT,

    session_id      TEXT,

    device_id       TEXT,

    event_time      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    activity        TEXT,

    severity        TEXT, -- TODO Enum.

    target_id       UUID,

    target_type     TEXT,

    -- Arbitrary additional data associated with the event.
    attachment      JSONB,
    attachment_type TEXT,

    PRIMARY KEY (tenant_id, event_id)

    -- TODO tenant_id FK
    -- TODO tenant_user_id FK
);

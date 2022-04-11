/*

 Use cases:

 - Use as an event log, for example to record being able or not being able to do something.

 - Record key user activity, such as authentication, password change, and so on.

 - Record actions taken against resources.

 - Support user service accounts.

 - Record system activity.

 - Record activity of support staff that are external to the tenant.

 */

-- TODO In our design, user accounts are separate from tenants. What this means is that
--      user activity doesn't belong to the tenants. Although this gives us flexibility to
--      support some interesting use cases (e.g., consultants and support staff), it
--      also creates problems. For example, it's a reasonable to expect to see authentication
--      failures associated with a corporate user. How do we resolve that? One way might
--      be to hav a separate user_audit log and to copy key authentication data into
--      tenant_audit_log. The idea being that joining an org also gives permission to the
--      org to monitor security events.
--
-- TODO Another problem is figuring out what to do with user accounts that are created
--      with the sole purpose of accessing a single tenant, when their access is revoked,
--      or when the tenant is cancelled.

CREATE TABLE tenant_audit_log
(
    tenant_id               UUID        NOT NULL REFERENCES tenants (tenant_id) ON DELETE CASCADE,

    event_id                UUID        NOT NULL DEFAULT gen_chrono_uuid(),

    PRIMARY KEY (tenant_id, event_id),


    -- Actor information.

    -- Who is the principal? For example: tenant user, external party user
    -- (e.g., support staff), system, and anonymous activity.
    actor_type              TEXT        NOT NULL, -- TODO Enum.

    -- Activity of support staff is recorded via their own identities, which are
    -- created on the fly. Such tenant user records probably shouldn't identify
    -- the staff, but show as their organization instead. In the UI we probably
    -- want to show just one meta tenant user, rather than the individual users.

    tenant_user_id          UUID REFERENCES tenant_users (tenant_user_id),

    -- To keep track of users' service accounts, for example for CLI and API access.
    tenant_user_identity_id UUID,

    -- Used to track the identity of the external/third-party organization for
    -- audit logs created for external users such as support staff.
    external_party_id       TEXT,


    -- Core event metadata, such as time and access location.

    timestamp               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Tracks means of interaction with the platform. In most cases this
    -- will be "app" or "api", but also other components where that makes sense.
    interface               TEXT        NOT NULL, -- TODO Enum.

    remote_addr             TEXT,

    session_id              TEXT,

    device_id               TEXT,

    request_id              TEXT,


    -- Information about the activity.

    category                TEXT        NOT NULL, -- TODO Enum

    activity                TEXT,

    severity                TEXT        NOT NULL, -- TODO Enum

    description             TEXT,


    -- Identity of the affected resource.

    resource_id             UUID,

    resource_type           TEXT,                 -- TODO Must not be NULL if resource_id is not NULL.


    -- Additional data associated with the event.

    attachment              JSONB,

    attachment_type         TEXT                  -- TODO Must not be NULL if attachment is not NULL.
);

-- TODO Prevent tenant_audit_log updates and deletes.

-- TODO Partition the tenant_audit_log table.

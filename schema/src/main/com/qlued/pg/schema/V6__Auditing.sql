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

    -- Who is the principal? For example: tenant user, external/third-party user
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
    external_tenant_id      UUID REFERENCES tenants (tenant_id) ON DELETE RESTRICT,


    -- Core event metadata, such as time and access location.

    timestamp               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Tracks means of interaction with the platform. In most cases this
    -- will be "app" or "api", but also other components where that makes sense.
    interface               TEXT        NOT NULL, -- TODO Enum.

    remote_addr             TEXT,                 -- TODO Better type.

    session_id              TEXT,

    device_id               TEXT,

    -- Unique transaction/request ID, where applicable. Usually generated
    -- at the edge, for example a CDN, reverse proxy, or web server.
    transaction_id          TEXT,


    -- Information about the activity itself.

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

-- TODO Row-level security.

-- TODO Prevent tenant_audit_log updates and deletes.

-- TODO Partition the tenant_audit_log table.

-- TODO Limits.

-- TODO On insert, the timestamp must be NOW().

/*

Events
------

user:

 created
 disabled
 enabled
 deleted

 signed_in
 signed_out

 used_new_device

 password_reset_requested
 password_reset_failed
 password_changed
 password_auth_successful
 password_auth_failed
 mfa_enabled
 mfa_disabled
 mfa_disabled_admin?
 mfa_codes_generated
 mfa_codes_viewed
 mfa_auth_hotp_successful
 mfa_auth_hotp_failed
 mfa_auth_code_successful
 mfa_auth_code_failed
 rme_auth_successful
 rme_auth_failed
 email_change_requested
 email_change_cancelled
 email_changed
 network_auth_successful
 network_auth_failed

 auth_blocked
 auth_unblocked
 auth_refused

 tenant_authz_successful
 -- tenant_authz_failed: mfa, network restrictions


tenant:

 created
 disabled
 enabled
 deleted

 mfa_enabled
 mfa_disabled

 -- TODO Network access control configuration updated
 -- TODO Owner/Admin access added and removed

 user_invited
 user_declined
 user_joined
 user_left
 user_disabled
 user_enabled
 user_removed
 user_disconnected
 user_access_requested
 user_access_approved
 user_access_refused

 user_session_authorized

 */
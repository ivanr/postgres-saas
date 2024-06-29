-- tenants

CREATE TABLE tenants
(
    tenant_id UUID DEFAULT gen_chrono_uuid(),

    name      TEXT NOT NULL,

    PRIMARY KEY (tenant_id)
);

ALTER TABLE tenants
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenants_policy ON tenants
    USING ((SELECT rls_get_tenant_id()::UUID) = tenant_id);

GRANT ALL ON tenants TO acme_role_tenant;


-- tenant_users

CREATE TABLE tenant_users
(
    tenant_id      UUID NOT NULL REFERENCES tenants (tenant_id) ON DELETE CASCADE,

    tenant_user_id UUID DEFAULT gen_chrono_uuid(),

    name           TEXT NOT NULL,

    PRIMARY KEY (tenant_id, tenant_user_id)
);

ALTER TABLE tenant_users
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_users_policy ON tenant_users
    USING ((SELECT rls_get_tenant_id()::UUID) = tenant_id);

GRANT ALL ON tenant_users TO acme_role_tenant;


-- tenant_notes

CREATE TABLE tenant_notes
(
    tenant_id UUID NOT NULL REFERENCES tenants (tenant_id) ON DELETE CASCADE,

    note_id   UUID DEFAULT gen_chrono_uuid(),

    note      TEXT NOT NULL,

    PRIMARY KEY (tenant_id, note_id)
);

ALTER TABLE tenant_notes
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_notes_policy ON tenant_notes
    USING ((SELECT rls_get_tenant_id()::UUID) = tenant_id);

GRANT ALL ON tenant_notes TO acme_role_tenant;

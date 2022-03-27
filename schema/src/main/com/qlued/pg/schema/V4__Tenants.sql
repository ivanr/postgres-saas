CREATE TABLE tenants
(
    tenant_id UUID DEFAULT gen_chrono_uuid(),

    name      TEXT NOT NULL,

    PRIMARY KEY (tenant_id)
);

CREATE TABLE tenant_notes
(
    tenant_id UUID,

    note_id   UUID DEFAULT gen_chrono_uuid(),

    note      TEXT NOT NULL,

    PRIMARY KEY (tenant_id, note_id)
);

ALTER TABLE tenant_notes
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_notes_policy ON tenant_notes
    USING (tenant_id = rls_get_tenant_id()::UUID);

GRANT ALL ON tenant_notes TO acme_role_tenant;


-- Test data

INSERT INTO tenants (tenant_id, name)
VALUES ('0000017f-c588-d0cf-ecde-ccc5ec98757b'::UUID, 'Acme');

INSERT INTO tenant_notes (tenant_id, note)
VALUES ('0000017f-c588-d0cf-ecde-ccc5ec98757b'::UUID, 'Acme:42');

INSERT INTO tenants (tenant_id, name)
VALUES ('0000017f-c5da-3736-7853-007773aee4d5'::UUID, 'Turbo');

INSERT INTO tenant_notes (tenant_id, note)
VALUES ('0000017f-c5da-3736-7853-007773aee4d5'::UUID::UUID, 'Turbo:42');


-- Fix ownership of newly-created objects.
REASSIGN OWNED BY acme_user_app_ddl TO acme_role_owner;

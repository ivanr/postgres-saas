-- Based on  https://www.2ndquadrant.com/en/blog/application-users-vs-row-level-security/
--       and https://github.com/2ndQuadrant/rls-examples/blob/master/signed-vault/signed_vault--1.0.sql

-- This table is designed to hold secrets that functions
-- can access, but database users can't. This is where
-- we will keep our row-level security secret.
CREATE TABLE system_vault
(
    secret_id TEXT,
    secret    TEXT
);

-- REVOKE ALL ON system_vault FROM PUBLIC;

INSERT INTO system_vault (secret_id, secret)
VALUES ('RLS', '1234');


-- Creates a signed token that gives the current connection permission
-- to access data that belongs to the specified organisation. This function
-- doesn't do anything special; it runs under the identity of the caller
-- and creates a HMAC signature with the provided key.
CREATE OR REPLACE FUNCTION rls_set_tenant_id(p_tenant_id TEXT, p_secret TEXT) RETURNS TEXT AS
$$
DECLARE
    v_data             TEXT;
    v_signature        BYTEA;
    v_signed_tenant_id TEXT;

BEGIN

    v_data := p_tenant_id || ':' || TRUNC(EXTRACT(epoch FROM now()));
    v_signature := hmac(v_data, p_secret, 'sha256');
    v_signed_tenant_id := v_data || ':' || encode(v_signature, 'hex');

    PERFORM set_config('rls.signed_tenant_id', v_signed_tenant_id, false);

    RETURN v_signed_tenant_id;

END;
$$ LANGUAGE plpgsql
    SECURITY INVOKER;


-- Retrieves an existing signed token, validates the signature,
-- and returns the current organisation identity. This function
-- is designed for use with row-level security policies. It
-- runs under the identity of the owner, which enables it to
-- access the underlying HMAC key to verify the signature.
CREATE OR REPLACE FUNCTION rls_get_tenant_id() RETURNS UUID AS
$$
DECLARE
    v_data             TEXT;
    v_tenant_id        TEXT;
    v_parts            TEXT[];
    v_secret           TEXT;
    v_signature_theirs BYTEA;
    v_signature_ours   BYTEA;
    v_signed_tenant_id TEXT;
    v_timestamp        INT;

BEGIN

    -- Get the HMAC key from the system vault table.

    SELECT secret INTO v_secret FROM system_vault WHERE secret_id = 'RLS';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'RLS: secret not found in the vault';
    END IF;

    -- Get the signed token.

    v_signed_tenant_id := current_setting('rls.signed_tenant_id', true);

    IF v_signed_tenant_id IS NULL THEN
        RAISE EXCEPTION 'RLS: signed tenant_id not found';
    END IF;

    -- Parse the token and generate our own signature from the same data.

    v_parts := regexp_matches(v_signed_tenant_id, '(.*):(.*):(.*)');

    --v_tenant_id := CAST(v_parts[1] AS INTEGER);
    v_tenant_id := v_parts[1];
    v_timestamp := v_parts[2];
    v_signature_theirs := decode(v_parts[3], 'hex');

    v_data := v_tenant_id || ':' || v_timestamp;
    v_signature_ours := hmac(v_data, v_secret, 'sha256');

    -- Validate the signature and the timestamp.

    IF (v_signature_theirs != v_signature_ours) THEN
        RAISE EXCEPTION 'RLS: invalid signature';
    END IF;

    IF NOW() > to_timestamp(v_timestamp) + INTERVAL '1 hour' THEN
        RAISE EXCEPTION 'RLS: expired signature';
    END IF;

    RETURN v_tenant_id::UUID;

END;
$$ LANGUAGE plpgsql
    SECURITY DEFINER
    STABLE;


-- Fix ownership of newly-created objects.
REASSIGN OWNED BY acme_user_app_ddl TO acme_role_owner;

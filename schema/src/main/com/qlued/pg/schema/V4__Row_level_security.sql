
-- Based on  https://www.2ndquadrant.com/en/blog/application-users-vs-row-level-security/
--       and https://github.com/2ndQuadrant/rls-examples/blob/master/signed-vault/signed_vault--1.0.sql

INSERT INTO system_vault (partition, key_id, key)
VALUES ('RLS', 'app.1', '1234');

-- Creates a signed token that gives the current connection permission
-- to access data that belongs to the specified organisation. This function
-- doesn't do anything special; it runs under the identity of the caller
-- and creates a HMAC signature with the provided key.
CREATE OR REPLACE FUNCTION rls_set_tenant_id(p_tenant_id TEXT, p_key_id TEXT, p_key TEXT) RETURNS TEXT AS
$$
DECLARE
    v_data_tbs         TEXT;
    v_signature        BYTEA;
    v_signed_tenant_id TEXT;

BEGIN

    -- Check that the input parameters are correctly formed.

    IF regexp_matches(p_tenant_id, '~') THEN
        RAISE EXCEPTION 'RLS: character ~ not allowed in parameter tenant_id';
    END IF;

    IF regexp_matches(p_key_id, '~') THEN
        RAISE EXCEPTION 'RLS: character ~ not allowed in parameter key_id';
    END IF;

    IF regexp_matches(p_key, '~') THEN
        RAISE EXCEPTION 'RLS: character ~ not allowed in parameter secret';
    END IF;

    -- Sign the tenant identifier.

    v_data_tbs := p_tenant_id || '~' || p_key_id || '~' || NOW();
    v_signature := hmac(v_data_tbs, p_key, 'sha256');
    v_signed_tenant_id := v_data_tbs || '~' || encode(v_signature, 'hex');

    -- Store the tenant token in the session storage for the other function to pick up.

    PERFORM set_config('rls.signed_tenant_id', v_signed_tenant_id, false);

    RETURN v_signed_tenant_id;

END ;
$$ LANGUAGE plpgsql
    SECURITY INVOKER;


-- Retrieves an existing signed token, validates the signature,
-- and returns the current organisation identity. This function
-- is designed for use with row-level security policies. It
-- runs under the identity of the owner, which enables it to
-- access the underlying HMAC key to verify the signature.
CREATE OR REPLACE FUNCTION rls_get_tenant_id() RETURNS TEXT AS
$$
DECLARE
    v_data_tbs         TEXT;
    v_tenant_id        TEXT;
    v_key_id           TEXT;
    v_parts            TEXT[];
    v_key              TEXT;
    v_signature_theirs BYTEA;
    v_signature_ours   BYTEA;
    v_signed_tenant_id TEXT;
    v_timestamp        TEXT;

BEGIN

    -- Get the signed token.

    v_signed_tenant_id := current_setting('rls.signed_tenant_id', /* missing_ok */ true);

    IF v_signed_tenant_id IS NULL THEN
        RAISE EXCEPTION 'RLS: tenant token not found';
    END IF;

    -- Extract parts from the token.

    v_parts := regexp_matches(v_signed_tenant_id, '(.*)~(.*)~(.*)~(.*)');
    IF (array_length(v_parts, /* array dimension */ 1)) != 4 THEN
        RAISE EXCEPTION 'RLS: invalid tenant token';
    END IF;

    v_tenant_id := v_parts[1];
    v_key_id := v_parts[2];
    v_timestamp := v_parts[3];
    v_signature_theirs := decode(v_parts[4], 'hex');

    -- Get the HMAC key from the system vault table.

    SELECT key INTO v_key FROM system_vault WHERE partition = 'RLS' AND key_id = v_key_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'RLS: unknown key: rls.%s', v_key_id ;
    END IF;

    -- Generate our own signature.

    v_data_tbs := v_tenant_id || '~' || v_key_id || '~' || v_timestamp;
    v_signature_ours := hmac(v_data_tbs, v_key, 'sha256');

    -- Validate the signature and the timestamp.

    IF (v_signature_theirs != v_signature_ours) THEN
        RAISE EXCEPTION 'RLS: invalid signature';
    END IF;

    -- The timestamp doesn't change within the transaction so a simple equality check will do.
    IF NOW()::TEXT != v_timestamp THEN
        RAISE EXCEPTION 'RLS: invalid timestamp: % %', NOW(), v_timestamp;
    END IF;

    RETURN v_tenant_id;

END;
$$ LANGUAGE plpgsql
    SECURITY DEFINER
    STABLE;


-- Fix ownership of newly-created objects.
REASSIGN OWNED BY acme_user_app_ddl TO acme_role_owner;

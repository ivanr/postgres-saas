
-- This table is designed to hold secrets that functions
-- can access, but database users can't. This is where
-- we will keep our row-level security secret.
CREATE TABLE system_vault
(
    partition TEXT NOT NULL,
    key_id    TEXT NOT NULL,
    key       TEXT NOT NULL,
    PRIMARY KEY (partition, key_id)
);

REVOKE ALL ON system_vault FROM PUBLIC;

-- Fix ownership of newly-created objects.
REASSIGN OWNED BY acme_user_app_ddl TO acme_role_owner;

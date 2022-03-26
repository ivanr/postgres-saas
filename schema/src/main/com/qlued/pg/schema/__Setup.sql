
-- Use a superuser account for these operations.

-- We start by creating a new role that will serve as the database
-- owner. Basically, the idea is to avoid using superuser accounts
-- as much as possible.

CREATE ROLE acme_role_owner NOLOGIN;

-- Create the new database, indicating its owner. As the owner, this
-- role will have unlimited privileges without having to grant it
-- permissions explicitly.

CREATE DATABASE acme OWNER acme_role_owner;

\c acme;


-- CVE-2018-1058: By default (up until version 15), all users can create
-- objects in the public schema. Removing this permission improves security.
-- https://wiki.postgresql.org/wiki/A_Guide_to_CVE-2018-1058%3A_Protect_Your_Search_Path
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Create a new schema for the acme application.
CREATE SCHEMA main AUTHORIZATION acme_role_owner;

-- Set search_path for the apps_owner user
ALTER ROLE acme_role_owner SET search_path TO main;


-- We create a further owner account with LOGIN privileges. This
-- enables us to have multiple accounts with the same privileges,
-- making it easier to understand who is doing what, apply
-- separate access control, and remove access without having to
-- change passwords.

-- The acme_user_app_ddl is the owner account we will use from the
-- application. It has full privileges over the database, which makes
-- it dangerous. We'll use it only for DDL operations (e.g., database
-- migrations.)

CREATE ROLE acme_user_app_ddl LOGIN;
GRANT acme_role_owner TO acme_user_app_ddl;
ALTER ROLE acme_user_app_ddl SET search_path TO main;


-- We create an admin role, which will have full access to the entire database, but no DDL.

CREATE ROLE acme_role_admin NOLOGIN BYPASSRLS;
ALTER ROLE acme_role_admin SET search_path TO main;

-- This role is allowed to connect to the database and use the schema.
GRANT CONNECT ON DATABASE acme TO acme_role_admin;
GRANT USAGE ON SCHEMA main TO acme_role_admin;

-- Configure the default privileges for objects that will be created in the future.
ALTER DEFAULT PRIVILEGES IN SCHEMA main
    GRANT ALL ON TABLES TO acme_role_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA main
    GRANT ALL ON SEQUENCES TO acme_role_admin;


-- We create a read-only admin role. This role should be used when it's necessary
-- to access the information in the database, but without the risk of inadvertently
-- making changes.

CREATE ROLE acme_role_admin_readonly NOLOGIN;
ALTER ROLE acme_role_admin_readonly SET search_path TO main;

-- This role is allowed to connect to the database and use the schema.
GRANT CONNECT ON DATABASE acme TO acme_role_admin_readonly;
GRANT USAGE ON SCHEMA main TO acme_role_admin_readonly;

-- Configure the default privileges for objects that will be created in the future.
ALTER DEFAULT PRIVILEGES IN SCHEMA main
    GRANT SELECT ON TABLES TO acme_role_admin_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA main
    GRANT SELECT ON SEQUENCES TO acme_role_admin_readonly;


-- We create a tenant role, which will have access only to the tenant tables. We will
-- further restrict this account using row level security. This will be the main role
-- used by the application.

CREATE ROLE acme_role_tenant NOLOGIN;
ALTER ROLE acme_role_tenant SET search_path TO main;

-- This role is allowed to connect to the database and use the schema.
GRANT CONNECT ON DATABASE acme TO acme_role_tenant;
GRANT USAGE ON SCHEMA main TO acme_role_tenant;

-- This role doesn't get access to any tables by default.

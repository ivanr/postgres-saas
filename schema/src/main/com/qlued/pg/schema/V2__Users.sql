-- Temporary users table, just enough to test UUID generation.

CREATE TABLE users
(

    user_id UUID DEFAULT gen_chrono_uuid(),

    name    TEXT NOT NULL,

    PRIMARY KEY (user_id)
);


-- Functions and triggers that are used to send change notifications.

CREATE FUNCTION tg_notify_user_change()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
DECLARE
    action TEXT := TG_ARGV[0];
BEGIN
    PERFORM (
        WITH payload ("table_name", "action", "timestamp", "user_id") AS
                 (
                     SELECT 'users', action, now(), OLD.user_id
                 )
        SELECT pg_notify('entity_change_notifications', row_to_json(payload)::TEXT)
        FROM payload
    );

    RETURN NULL;
END;
$$;

CREATE TRIGGER notify_user_update
    AFTER UPDATE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE tg_notify_user_change('update');

CREATE TRIGGER notify_user_delete
    AFTER DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE tg_notify_user_change('delete');


-- Some simple test operations to exercise the above code.

INSERT INTO users (name)
VALUES ('John');

UPDATE users
SET name = 'Smith';


-- By default, when a new object is created it is owner by the role that
-- created. In a situation where we have potentially multiple roles
-- creating objects in the same schema, we want to keep things simple
-- and revert to the same underlying object.
--
-- TODO Implement via a Flyway callback?

REASSIGN OWNED BY acme_user_app_ddl TO acme_role_owner;

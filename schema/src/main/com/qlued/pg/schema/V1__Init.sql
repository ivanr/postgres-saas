
-- Random UUIDs have certain disadvantages when it comes to
-- indexing performance. In our "chrono" UUID, the first 8
-- bytes are time based, and the second 8 bytes are random. This
-- approach should address the performance issues while also
-- providing enough randomness.
--
-- Reference: https://www.2ndquadrant.com/en/blog/sequential-uuid-generators/

CREATE EXTENSION pgcrypto;

CREATE OR REPLACE FUNCTION gen_chrono_uuid(OUT result UUID) AS $$
DECLARE
    millis BIGINT;
BEGIN

    SELECT FLOOR (
            EXTRACT (EPOCH FROM clock_timestamp()) * 1000
        )
        INTO millis;

    SELECT CAST (
            lpad(to_hex(CAST (millis AS BIGINT)), 16, '0')
                || substring(CAST (gen_random_bytes(8) AS TEXT), 3) AS UUID
        )
        INTO result;

END;
$$
LANGUAGE PLPGSQL;


-- Temporary users table, just enough to test UUID generation.

CREATE TABLE users (

    user_id UUID DEFAULT gen_chrono_uuid(),

    name TEXT NOT NULL,

    PRIMARY KEY (user_id)
);

INSERT INTO users ( name ) VALUES ('Anonymous');

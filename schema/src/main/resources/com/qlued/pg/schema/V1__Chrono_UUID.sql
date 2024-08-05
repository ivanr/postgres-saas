
-- Random UUIDs have certain disadvantages when it comes to
-- indexing performance. In our "chrono" UUID, the first 8
-- bytes are time based, and the second 8 bytes are random. This
-- approach should address the performance issues while also
-- providing enough randomness.
--
-- Reference: https://www.2ndquadrant.com/en/blog/sequential-uuid-generators/

-- Another option is: https://github.com/pksunkara/pgx_ulid
-- And https://www.rfc-editor.org/rfc/rfc9562.html will probably be supported soon.
--
-- Also: Implementing UUIDs v7 in pure SQL
-- https://postgresql.verite.pro/blog/2024/07/15/uuid-v7-pure-sql.html
--
-- pg_uuidv7
-- https://github.com/fboulnois/pg_uuidv7

CREATE EXTENSION IF NOT EXISTS pgcrypto;

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

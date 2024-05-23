CREATE OR REPLACE PROCEDURE pg_advisory_xact_lock(text) AS
$$
BEGIN
    PERFORM pg_advisory_xact_lock(
            concat('x' || lpad(encode(digest($1, 'sha256'), 'hex'), 16, '0'))::bit(64)::BIGINT
            );
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_try_advisory_xact_lock(text)
    returns BOOLEAN
AS
$$
DECLARE
    r BOOLEAN;
BEGIN
    r := (SELECT pg_try_advisory_xact_lock(
                         concat('x' || lpad(encode(digest($1, 'sha256'), 'hex'), 16, '0'))::bit(64)::BIGINT
                 ) AS b);
    -- RAISE EXCEPTION 'Return: %', r;
    RETURN r;
END
$$ LANGUAGE plpgsql;

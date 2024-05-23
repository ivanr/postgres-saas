/*

In Postgres, advisory lock functions take either two int4 values, or one int8 value. As
a result, these functions are somewhat difficult to use. The functions below provide
a more ergonomic approach where arbitrary text is converted into a Postgres lock via
hashing. There are 2^64 possible combinations, so the likelihood of conflict is not
great, but it's still low.

*/

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
    RETURN (SELECT pg_try_advisory_xact_lock(
                           concat('x' || lpad(encode(digest($1, 'sha256'), 'hex'), 16, '0'))::bit(64)::BIGINT
                   ) AS b);
END
$$ LANGUAGE plpgsql;

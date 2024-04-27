#!/bin/bash
set -e

echo "Creating partman extension"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE SCHEMA partman;
    CREATE EXTENSION pg_partman SCHEMA partman;

    CREATE ROLE partman_user WITH LOGIN;
    GRANT ALL ON SCHEMA partman TO partman_user;
    GRANT ALL ON ALL TABLES IN SCHEMA partman TO partman_user;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA partman TO partman_user;
    GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA partman TO partman_user;
EOSQL

echo "ADDING pg_partman_bgw TO postgresql.conf"
echo "shared_preload_libraries = 'pg_partman_bgw'" >> $PGDATA/postgresql.conf
echo "pg_partman_bgw.interval = 60" >> $PGDATA/postgresql.conf
echo "pg_partman_bgw.role = '$POSTGRES_USER'" >> $PGDATA/postgresql.conf
echo "pg_partman_bgw.dbname = '$POSTGRES_DB'" >> $PGDATA/postgresql.conf

echo "Enabling logging of all statements"
cat >> /var/lib/postgresql/data/postgresql.conf <<-END
log_statement = 'all'
END

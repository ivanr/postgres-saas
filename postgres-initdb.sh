#!/bin/bash
set -e

createdb saas

cat >> /var/lib/postgresql/data/postgresql.conf <<-END
log_statement         = 'all'
END

/*

Here we have an example of shuffle sharding, which provides a level of
resiliency against noisy neighbours in multi-tenant systems. The idea
is to:

 1. Create N virtual shards (e.g., 65,536).

 2. Divide the queue into M actual shards (8 in this example).

 3. Assign each tenant to 2 virtual shards.

 4. When adding to the queue, insert each entry into the least
    busy shard assigned to the tenant.

With this approach, a large volume of entries from one tenant will
saturate two shards, but the remaining 6 shards will continue to
serve the other 7 tenants.

Increasing the number of shards increases the resiliency.

The use of virtual shards decouples tenant assignments to that
they don't have to be changed should you wish to change the
number of underlying actual shards (e.g., to support growth).

For estimation of queue sizes, use TABLESAMPLE with the SYSTEM method:
https://www.postgresql.org/docs/current/sql-select.html#:~:text=a%20tablesample%20clause

Another advantage of partitioning is that it's possible to use
multiple pullers, one per partition, to avoid locking. If it's not
necessary to process rows in a particular orders, indexes are
not necessary either.

To manage bloat [without further time-based/2nd-level partitioning],
each puller can periodically stop processing rows to recreate the
partitions while preserving the rows that haven't been processed yet.

 */

CREATE TABLE tenant_queue
(
    tenant_id  UUID        NULL REFERENCES tenants (tenant_id) ON DELETE CASCADE,

    entry_id   UUID        NOT NULL DEFAULT gen_chrono_uuid(),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    data       JSONB       NOT NULL,

    shard      SMALLINT,

    PRIMARY KEY (tenant_id, entry_id, shard)

) PARTITION BY LIST (shard);

CREATE TABLE tenant_queue_p1 PARTITION OF tenant_queue
    FOR VALUES IN (1);

CREATE TABLE tenant_queue_p2 PARTITION OF tenant_queue
    FOR VALUES IN (2);

CREATE TABLE tenant_queue_p3 PARTITION OF tenant_queue
    FOR VALUES IN (3);

CREATE TABLE tenant_queue_p4 PARTITION OF tenant_queue
    FOR VALUES IN (4);

CREATE TABLE tenant_queue_p5 PARTITION OF tenant_queue
    FOR VALUES IN (5);

CREATE TABLE tenant_queue_p6 PARTITION OF tenant_queue
    FOR VALUES IN (6);

CREATE TABLE tenant_queue_p7 PARTITION OF tenant_queue
    FOR VALUES IN (7);

CREATE TABLE tenant_queue_p8 PARTITION OF tenant_queue
    FOR VALUES IN (8);

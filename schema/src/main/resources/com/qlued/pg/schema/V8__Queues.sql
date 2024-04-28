/*

Here we have an example of shuffle sharding, which provides a level of
resiliency against noisy neighbours in multi-tenant systems. The idea
is to:

 1. Divide the queue into N shards (8 in this example).

 2. Assign each tenant to M shards (2 in this example).

 3. When adding to the queue, insert each entry into the least
    busy shard assigned to the tenant.

With this approach, a large volume of entries from one tenant will
saturate two shards, but the remaining 6 shards will continue to
serve the other 7 tenants.

Increasing the number of shards increases the resiliency.

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

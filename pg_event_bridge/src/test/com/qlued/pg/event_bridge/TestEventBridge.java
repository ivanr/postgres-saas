package com.qlued.pg.event_bridge;

import org.junit.jupiter.api.Test;

public class TestEventBridge {

    @Test
    public void test() throws Exception {
        PgJdbcEventBridge bridge = PgJdbcEventBridge.builder()
                .jdbcUrl("jdbc:pgsql://localhost/saas")
                .username("postgres")
                .build();

        bridge.startThread();

        bridge.registerListener("entity_change_notifications", new EventListener() {
            @Override
            public void receive(PostgresEvent event) {
                System.err.println("Listener received event: " + event.getChannel() + ": " + event.getPayload());
            }
        });

        // At this point it's likely that a connection has not yet been established,
        // but our notification will be queued and sent later.
        bridge.notify("entity_change_notifications", "1");

        Thread.sleep(5_000);

        bridge.shutDown();
    }
}

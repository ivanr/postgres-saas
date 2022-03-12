package com.qlued.pg.event_bridge;

import org.junit.jupiter.api.Test;

public class TestEventBridge {

    @Test
    public void test() throws Exception {
        PostgresEventBridge bridge = PostgresEventBridge.builder()
                .jdbcUrl("jdbc:pgsql://localhost/saas")
                .username("postgres")
                .channelName("entity_change_notifications")
                .build();

        Thread t = new Thread(bridge);
        t.start();
        t.join();
    }
}

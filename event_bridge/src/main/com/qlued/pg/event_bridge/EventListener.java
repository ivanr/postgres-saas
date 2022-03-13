package com.qlued.pg.event_bridge;

public interface EventListener {

    void receive(PostgresEvent event);
}

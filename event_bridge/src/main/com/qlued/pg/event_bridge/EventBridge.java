package com.qlued.pg.event_bridge;

public interface EventBridge {

    void notify(String channel, String payload);

    boolean registerListener(String channel, EventListener listener);
}

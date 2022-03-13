package com.qlued.pg.event_bridge;

import lombok.Builder;
import lombok.Data;

@Builder
@Data
public class PostgresEvent {
    private String channel;
    private String payload;
}

package com.qlued.pg.event_bridge;

import com.impossibl.postgres.api.jdbc.PGConnection;

import java.sql.PreparedStatement;
import java.sql.SQLException;

public class NotifyCommand implements PostgresCommand {

    private final String channel;

    private final String payload;

    public NotifyCommand(String channel, String payload) {
        this.channel = channel;
        this.payload = payload;
    }

    public static void run(PGConnection connection, String methodChannel, String methodPayload) throws SQLException {
        try (PreparedStatement stmt = connection.prepareStatement("SELECT pg_notify(? , ?)")) {
            stmt.setString(1, methodChannel);
            stmt.setString(2, methodPayload);
            stmt.executeQuery();
        }
    }

    @Override
    public void run(PGConnection connection) throws SQLException {
        run(connection, channel, payload);
    }
}

package com.qlued.pg.event_bridge;

import com.impossibl.postgres.api.jdbc.PGConnection;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;

import java.sql.SQLException;
import java.sql.Statement;

@Slf4j
public class ListenCommand implements PostgresCommand {

    private final String channel;

    public ListenCommand(@NonNull String channel) {
        this.channel = channel;
    }

    public static void run(PGConnection connection, String methodChannel) throws SQLException {
        try (Statement stmt = connection.createStatement()) {
            // Postgres: "Quoted identifiers can contain any character, except the character
            // with code zero. (To include a double quote, write two double quotes.)"
            // https://www.postgresql.org/docs/current/sql-syntax-lexical.html
            //
            // Note that Statement#enquoteIdentifier doesn't escape, it only enquotes. But
            // we don't need to escape because we accept only strings that use a limited
            // character set and don't allow double quotes.
            //
            // Aside: If wanted to quote identifiers portably, a call to
            // Connection.getMetaData().getIdentifierQuoteString() returns what to use.

            // TODO Escape identifier for extra safety.
            stmt.executeUpdate("LISTEN " + stmt.enquoteIdentifier(methodChannel, true));
            log.info("Executed: LISTEN " + methodChannel);
        }
    }

    @Override
    public void run(PGConnection connection) throws SQLException {
        run(connection, channel);
    }
}

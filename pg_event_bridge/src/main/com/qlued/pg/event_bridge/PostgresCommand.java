package com.qlued.pg.event_bridge;

import com.impossibl.postgres.api.jdbc.PGConnection;

import java.sql.SQLException;

public interface PostgresCommand {

    void run(PGConnection connection) throws SQLException;
}

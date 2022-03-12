package com.qlued.pg.event_bridge;

import com.impossibl.postgres.api.jdbc.PGConnection;
import com.impossibl.postgres.api.jdbc.PGNotificationListener;
import lombok.Builder;
import lombok.extern.slf4j.Slf4j;

import java.sql.DriverManager;
import java.sql.Statement;

@Slf4j
public class PostgresEventBridge implements Runnable {

    private String channelName;

    private String jdbcUrl;

    private String username;

    private String password;

    private PGConnection connection;

    private final Object lock = new Object[0];

    private boolean running = true;

    @Builder
    public PostgresEventBridge(String channelName, String jdbcUrl, String username, String password) {
        this.channelName = channelName;
        this.jdbcUrl = jdbcUrl;
        this.username = username;
        this.password = password;
    }

    public void run() {
        try {
            for (; ; ) {
                // Connect to the database in
                // a loop until we succeed.
                while (connection == null) {
                    try {
                        connection = connectToPostgres();
                        log.warn("Event bus '{}' connected", channelName);
                    } catch (Exception e) {
                        log.error("Event bus '{}' failed to connect", channelName, e);
                        Thread.sleep(1_000);
                    }
                }

                // This thread doesn't do much. We wait here until notified,
                // at which point we either exit or reopen the connection.

                synchronized (lock) {
                    lock.wait();
                }

                if (!running) {
                    if (connection != null) {
                        try {
                            connection.close();
                        } catch (Exception e) {
                            // Close quietly.
                        } finally {
                            connection = null;
                        }
                    }

                    return;
                }
            }
        } catch (InterruptedException e) {
            // Nothing to do, just stop.
        }
    }

    private PGConnection connectToPostgres() throws Exception {
        PGConnection newConnection = DriverManager.getConnection(jdbcUrl, username, password)
                .unwrap(PGConnection.class);

        try {
            newConnection.addNotificationListener(new PGNotificationListener() {

                @Override
                public void notification(int processId, String channelName, String payload) {
                    log.info("Event bus '{}' received message: {}", channelName, payload);
                }

                @Override
                public void closed() {
                    log.warn("Event bus '{}' connection closed", channelName);
                    connection = null;
                    synchronized (lock) {
                        // If we're still supposed to run, notify
                        // the main thread so that it can reconnect.
                        if (running) {
                            lock.notify();
                        }
                    }
                }
            });

            try (Statement stmt = newConnection.createStatement()) {
                stmt.executeUpdate("LISTEN " + channelName);
            }

            return newConnection;
        } catch (Exception e) {
            if (newConnection != null) {
                newConnection.close();
            }

            throw e;
        }
    }

    protected void shutDown() {
        synchronized (lock) {
            running = false;
            lock.notify();
        }
    }
}

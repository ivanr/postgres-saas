package com.qlued.pg.event_bridge;

import com.impossibl.postgres.api.jdbc.PGConnection;
import com.impossibl.postgres.api.jdbc.PGNotificationListener;
import lombok.Builder;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;

import java.sql.Connection;
import java.sql.DriverManager;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.regex.Pattern;

import static java.util.stream.Collectors.toUnmodifiableSet;

// This bridge is currently implemented using async notifications that
// are supported by PGJDBC-NG, https://impossibl.github.io/pgjdbc-ng/
// It's not clear if this JDBC driver can replace the official one, so the
// choice would be to have two separate JDBC drivers in the application,
// or implement notifications using the official driver. In the latter
// case, we'd have to poll the database with dummy queries because the
// notifications are not async. For more information, see:
// https://jdbc.postgresql.org/documentation/head/listennotify.html

@Slf4j
public class PgJdbcEventBridge implements EventBridge, Runnable {

    private String jdbcUrl;

    private String username;

    private String password;

    private volatile PGConnection persistentConnection;

    private Thread backgroundThread;

    private CountDownLatch shutdownLatch = new CountDownLatch(1);

    private Set<EventListenerRecord> listeners = new HashSet<>();

    private LinkedBlockingDeque<PostgresCommand> queue = new LinkedBlockingDeque<>();

    @Data
    @Builder
    public static class EventListenerRecord {
        private String channel;
        private EventListener listener;
    }

    @Builder

    public PgJdbcEventBridge(String channel, String jdbcUrl, String username, String password) {
        this.jdbcUrl = jdbcUrl;
        this.username = username;
        this.password = password;
    }

    @Override
    public void notify(String channel, String payload) {
        queue.add(new NotifyCommand(channel, payload));
    }

    @Override
    public boolean registerListener(String channel, EventListener listener) {
        try {
            // TODO If we're called before our first connection is established,
            //      we'll call LISTEN during connection setup but then send
            //      another LISTEN via the queued command.
            queue.add(new ListenCommand(channel));
        } catch (Exception e) {
            // TODO Don't log this exception if it's not a connection problem. If
            //      the connection break, we'll reconnect, and run LISTEN again.
            log.info("LISTEN command failed", e);
        }

        return listeners.add(EventListenerRecord.builder()
                .channel(channel)
                .listener(listener)
                .build());
    }

    private PGConnection connectToPostgres() throws Exception {
        Connection newJdbcConnection = DriverManager.getConnection(jdbcUrl, username, password);
        newJdbcConnection.setAutoCommit(true);

        PGConnection newConnection = newJdbcConnection.unwrap(PGConnection.class);

        log.info("Connection established");

        try {
            newConnection.addNotificationListener(new PGNotificationListener() {

                @Override
                public void notification(int processId, String channel, String payload) {
                    log.info("Event bridge received message on channel {}: {}", channel, payload);

                    PostgresEvent event = new PostgresEvent(channel, payload);
                    for (EventListenerRecord r : listeners) {
                        if (channel.compareToIgnoreCase(r.getChannel()) == 0) {
                            r.getListener().receive(event);
                        }
                    }
                }

                @Override
                public void closed() {
                    log.warn("Connection closed");
                    persistentConnection = null;
                    backgroundThread.interrupt();
                }
            });

            // If we've reconnected, register for the notifications again.

            Set<String> channelNames = listeners.stream().
                    map(EventListenerRecord::getChannel)
                    .collect(toUnmodifiableSet());

            for (String channel : channelNames) {
                ListenCommand.run(newConnection, channel);
            }

            return newConnection;
        } catch (Exception e) {
            closeQuietly(newConnection);
            throw e;
        }
    }

    public static boolean isValidChannelName(String channel) {
        return Pattern.compile("^[\\p{Alpha}][\\p{Alnum}_.]+$").matcher(channel).matches();
    }

    public void startThread() {
        backgroundThread = new Thread(this);
        backgroundThread.setName(this.getClass().getName());
        backgroundThread.setDaemon(true);
        backgroundThread.start();
    }

    public void run() {
        try {
            // We loop forever, first connecting the Postgres, then sending
            // commands, also forever. If a connection breaks, we restart
            // the loop, reconnect, then continue sending commands.

            for (; ; ) {
                // Connect to the database in a loop until we succeed, or we're told to shut down.
                while ((persistentConnection == null) && (shutdownLatch.getCount() != 0)) {
                    try {
                        persistentConnection = connectToPostgres();
                    } catch (Exception e) {
                        log.error("Connection failed", e);
                        Thread.sleep(1_000);
                    }
                }

                // Send commands, waiting if necessary. We'll be interrupted if
                // something bad happens to the connection, or if we need to shut down.
                while (!Thread.currentThread().isInterrupted()) {
                    PostgresCommand command = queue.take();
                    try {
                        command.run(persistentConnection);
                    } catch (Exception e) {
                        // We'll be here if we fail to process the command,
                        // either because there is a problem with the connection
                        // or command, or if the thread is interrupted.

                        // Return the failed command back into the queue.
                        queue.addFirst(command);

                        // Exit the command loop to figure out what to
                        // do, either exit or mend the connection.
                        break;
                    }
                }

                // Exit, if it's time. Otherwise, continue in the loop to
                // reconnect and resume command processing.
                if (shutdownLatch.getCount() == 0) {
                    closeQuietly(persistentConnection);
                    return;
                }
            }
        } catch (InterruptedException e) {
            // Nothing to do, just exit the thread. We'll end up
            // here if we're interrupted while we're attempting to
            // connect.
        }
    }

    public void shutDown() {
        shutdownLatch.countDown();
        backgroundThread.interrupt();
    }

    private void closeQuietly(PGConnection connection) {
        if (connection == null) {
            return;
        }

        try {
            connection.close();
        } catch (Exception ignored) {
            // Close quietly.
        }
    }
}

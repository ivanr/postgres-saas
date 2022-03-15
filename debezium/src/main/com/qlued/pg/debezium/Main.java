package com.qlued.pg.debezium;

import io.debezium.config.Configuration;
import io.debezium.connector.postgresql.PostgresConnector;
import io.debezium.connector.postgresql.PostgresConnectorConfig;
import io.debezium.engine.DebeziumEngine;
import io.debezium.engine.RecordChangeEvent;
import io.debezium.engine.format.ChangeEventFormat;
import io.debezium.engine.format.Protobuf;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.source.SourceRecord;
import org.apache.kafka.connect.storage.MemoryOffsetBackingStore;

import java.io.IOException;
import java.util.List;
import java.util.function.Function;

/*

CREATE PUBLICATION debezium;

ALTER PUBLICATION debezium ADD TABLE users;

SELECT pg_create_logical_replication_slot('debezium', 'pgoutput');

CREATE ROLE debezium WITH REPLICATION LOGIN;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium;
GRANT SELECT ON public.users TO debezium;

Useful: https://www.digitalocean.com/community/tutorials/how-to-set-up-logical-replication-with-postgresql-10-on-ubuntu-18-04

 */

@Slf4j
public class Main {

    private DebeziumEngine engine;

    public void startEngine() {
        // Parameter documentation:
        // https://debezium.io/documentation/reference/1.8/connectors/postgresql.html#postgresql-connector-properties
        Configuration config = Configuration.empty()
                .withSystemProperties(Function.identity()).edit()
                .with("offset.storage", MemoryOffsetBackingStore.class)
                .with("snapshot.mode", PostgresConnectorConfig.SnapshotMode.ALWAYS)

                .with("name", "debezium-poc")
                .with("connector.class", PostgresConnector.class)
                .with("plugin.name", "pgoutput")
                .with("slot.name", "debezium")
                .with("slot.drop.on.stop", "false")
                .with("publication.name", "debezium")

                .with("database.hostname", "localhost")
                .with("database.port", 5432)
                .with("database.user", "debezium")
                //.with("database.password", "")
                .with("database.dbname", "saas")
                .with("database.server.name", "server1")

                //.with("schema.include.list", "")
                //.with("schema.exclude.list", "")
                //.with("database.include.list", "")
                //.with("database.exclude.list", "")
                .with("table.include.list", "public.users")
                //.with("table.exclude.list", "")
                //.with("column.include.list", "")
                //.with("column.exclude.list", "")

                .with("publication.autocreate.mode", "disabled")

                .build();

        //engine = DebeziumEngine.create(ChangeEventFormat.of(Connect.class)) // Consuming SourceRecord instances.
        engine = DebeziumEngine.create(ChangeEventFormat.of(Protobuf.class))
                .using(config.asProperties())
                .notifying(new ProtobufBatchConsumer())
                .build();

        // Shut down the engine cleanly on JVM exit.
        Runtime.getRuntime().addShutdownHook(new Thread() {
            public void run() {
                try {
                    engine.close();
                } catch (IOException e) {
                    log.warn("Exception during engine close", e);
                }
            }
        });

        engine.run();
    }

    // Useful links:
    // - Debezium Server
    //   https://github.com/debezium/debezium/blob/main/debezium-server/debezium-server-core/src/main/java/io/debezium/server/DebeziumServer.java
    // - Kinesis consumer implementation:
    //   https://github.com/debezium/debezium/blob/main/debezium-server/debezium-server-kinesis/src/main/java/io/debezium/server/kinesis/KinesisChangeConsumer.java

    public class ProtobufBatchConsumer implements DebeziumEngine.ChangeConsumer<RecordChangeEvent<byte[]>> {

        @Override
        public void handleBatch(List<RecordChangeEvent<byte[]>> events,
                                DebeziumEngine.RecordCommitter<RecordChangeEvent<byte[]>> committer) throws InterruptedException {
            for (RecordChangeEvent<byte[]> event : events) {
                // TODO Forward event.record()
                committer.markProcessed(event);
            }

            committer.markBatchFinished();
        }
    }

    static class SourceRecordBatchConsumer implements DebeziumEngine.ChangeConsumer<RecordChangeEvent<SourceRecord>> {

        @Override
        public void handleBatch(List<RecordChangeEvent<SourceRecord>> changeEvents,
                                DebeziumEngine.RecordCommitter<RecordChangeEvent<SourceRecord>> committer) throws InterruptedException {
            for (RecordChangeEvent<SourceRecord> changeEvent : changeEvents) {
                log.info("Received change event '{}'", changeEvent);

                SourceRecord record = changeEvent.record();
                Struct payload = (Struct) record.value();
                if (payload == null) {
                    return;
                }

                // TODO Do something with the record. For example, take a different path
                //      based on operation: Envelope.Operation.forCode(payload.getString("op").

                committer.markProcessed(changeEvent);
            }

            committer.markBatchFinished();
        }
    }

    public static void main(String[] args) {
        //System.setProperty(org.slf4j.impl.SimpleLogger.DEFAULT_LOG_LEVEL_KEY, "TRACE");

        Main main = new Main();
        main.startEngine();
    }
}

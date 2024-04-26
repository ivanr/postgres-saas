package com.qlued.pg.schema;

import org.flywaydb.core.Flyway;

public class RunMigrations {

    public static void main(String[] args) {
        // Initialize the database. We have to run this as
        // a separate step because we don't want to use the
        // public schema.

        Flyway flywayInit = Flyway.configure()
                .dataSource(
                        "jdbc:postgresql://localhost:55432/saas",
                        "postgres",
                        "")
                .sqlMigrationPrefix("M")
                .locations("com/qlued/pg/schema")
                .failOnMissingLocations(true)
                .load();

        flywayInit.migrate();

        // Now run the migrations, using the new "main"
        // schema created during setup.

        Flyway flyway = Flyway.configure()
                .dataSource(
                        "jdbc:postgresql://localhost:55432/saas",
                        "acme_user_app_ddl",
                        "acme_user_app_ddl")
                .defaultSchema("main")
                .locations("com/qlued/pg/schema")
                .failOnMissingLocations(true)
                .load();

        flyway.migrate();
    }
}

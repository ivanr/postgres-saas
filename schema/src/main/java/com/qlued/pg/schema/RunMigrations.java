package com.qlued.pg.schema;

import org.flywaydb.core.Flyway;

public class RunMigrations {

    public static void main(String[] args) {

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
                .cleanDisabled(false)
                .load();

        flyway.clean();
        flyway.migrate();
    }
}

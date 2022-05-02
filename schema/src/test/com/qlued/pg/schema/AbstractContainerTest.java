package com.qlued.pg.schema;

import org.apache.ibatis.exceptions.PersistenceException;
import org.apache.ibatis.io.Resources;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.BeforeAll;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.io.IOException;
import java.util.Properties;

@Testcontainers
public abstract class AbstractContainerTest {

    @Container
    private static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:latest");

    protected static SqlSessionFactory ddlSessionFactory;

    protected static SqlSessionFactory adminSessionFactory;

    protected static SqlSessionFactory tenantSessionFactory;

    @BeforeAll
    public static void init() throws IOException {
        // Initialize the database. We have to run this as
        // a separate step because we don't want to use the
        // public schema.
        Flyway flywayInit = Flyway.configure()
                .dataSource(
                        postgres.getJdbcUrl(),
                        postgres.getUsername(),
                        postgres.getPassword())
                .sqlMigrationPrefix("M")
                .locations("com/qlued/pg/schema")
                .failOnMissingLocations(true)
                .load();

        flywayInit.clean();
        flywayInit.migrate();

        // Build the schema.
        Flyway flyway = Flyway.configure()
                .dataSource(
                        postgres.getJdbcUrl(),
                        "acme_user_app_ddl",
                        "acme_user_app_ddl")
                .defaultSchema("main")
                .locations("com/qlued/pg/schema")
                .failOnMissingLocations(true)
                .load();

        flyway.clean();
        flyway.migrate();

        // Initialize MyBatis.
        Properties properties = new Properties();
        properties.put("db.url", postgres.getJdbcUrl());
        String resource = "com/qlued/pg/schema/mybatis.xml";

        ddlSessionFactory = new SqlSessionFactoryBuilder().build(
                Resources.getResourceAsStream(resource),
                "ddl", properties);

        adminSessionFactory = new SqlSessionFactoryBuilder().build(
                Resources.getResourceAsStream(resource),
                "admin", properties);

        tenantSessionFactory = new SqlSessionFactoryBuilder().build(
                Resources.getResourceAsStream(resource),
                "tenant", properties);
    }

    protected boolean isRowLevelSecurityViolation(PersistenceException exception) {
        return (exception.getMessage() != null)
                && (exception.getMessage().contains("new row violates row-level security policy"));
    }
}

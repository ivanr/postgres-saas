package com.qlued.pg.schema;

import org.apache.ibatis.io.Resources;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.io.IOException;
import java.util.Map;
import java.util.Properties;

@Testcontainers
public class ContainerTest {

    @Container
    private static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:latest");

    protected static SqlSessionFactory sessionFactory;

    @BeforeAll
    public static void init() throws IOException {
        // Initialize the database.
        Flyway flyway = Flyway.configure()
                .dataSource(
                        postgres.getJdbcUrl(),
                        postgres.getUsername(),
                        postgres.getPassword())
                .locations("com/qlued/pg/schema")
                .failOnMissingLocations(true)
                .placeholders(Map.of("dbname", postgres.getDatabaseName()))
                .load();

        flyway.clean();
        flyway.migrate();

        // Initialize MyBatis.
        Properties properties = new Properties();
        properties.put("db.url", postgres.getJdbcUrl());
        properties.put("db.username", postgres.getUsername());
        properties.put("db.password", postgres.getPassword());
        String resource = "com/qlued/pg/schema/mybatis.xml";
        sessionFactory = new SqlSessionFactoryBuilder().build(
                Resources.getResourceAsStream(resource),
                "ddl", properties);
    }

    @Test
    public void test() {
        //System.out.println(postgres.getJdbcUrl());

        try (SqlSession session = sessionFactory.openSession()) {
        }
    }
}

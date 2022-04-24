package com.qlued.pg.schema;

import org.apache.ibatis.io.Resources;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.BeforeAll;

import java.io.IOException;
import java.util.Properties;

public class AbstractDatabaseTest {

    protected static SqlSessionFactory ddlSessionFactory;

    protected static SqlSessionFactory adminSessionFactory;

    protected static SqlSessionFactory tenantSessionFactory;

    @BeforeAll
    public static void init() throws IOException {
        Properties properties = new Properties();
        properties.load(Resources.getResourceAsStream("com/qlued/pg/schema/test.properties"));

        // Reset the database schema.

        Flyway flyway = Flyway.configure()
                .dataSource(
                        properties.getProperty("db.url"),
                        properties.getProperty("db.ddl.username"),
                        properties.getProperty("db.ddl.password"))
                .locations("com/qlued/pg/schema")
                .failOnMissingLocations(true)
                .load();

        flyway.clean();
        flyway.migrate();

        // Initialize MyBatis.

        String resource = "com/qlued/pg/schema/mybatis.xml";

        ddlSessionFactory = new SqlSessionFactoryBuilder().build(
                Resources.getResourceAsStream(resource),
                "ddl");

        adminSessionFactory = new SqlSessionFactoryBuilder().build(
                Resources.getResourceAsStream(resource),
                "admin");

        tenantSessionFactory = new SqlSessionFactoryBuilder().build(
                Resources.getResourceAsStream(resource),
                "tenant");
    }
}

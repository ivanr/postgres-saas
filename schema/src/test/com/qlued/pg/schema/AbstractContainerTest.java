package com.qlued.pg.schema;

import org.apache.ibatis.exceptions.PersistenceException;
import org.apache.ibatis.io.Resources;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.BeforeAll;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.output.Slf4jLogConsumer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;
import org.testcontainers.utility.MountableFile;

import java.io.IOException;
import java.util.Properties;

@Testcontainers
public abstract class AbstractContainerTest {

    private static Logger logger = LoggerFactory.getLogger(AbstractContainerTest.class);

    @Container
    private static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>(

            DockerImageName.parse("postgres-saas-postgres")
                    .asCompatibleSubstituteFor("postgres"))
            .withCopyFileToContainer(
                    MountableFile.forHostPath(System.getProperty("user.dir") + "/../postgres-initdb.sh"),
                    "/docker-entrypoint-initdb.d/initdb.sh")
            .withCommand("postgres -c log_statement=all");

    protected static SqlSessionFactory adminSessionFactory;

    protected static SqlSessionFactory tenantSessionFactory;

    @BeforeAll
    public static void init() throws IOException {
        Slf4jLogConsumer logConsumer = new Slf4jLogConsumer(logger);
        postgres.followOutput(logConsumer);

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

        flywayInit.migrate();

        // Now run the migrations, using the new "main"
        // schema created during setup.

        Flyway flyway = Flyway.configure()
                .dataSource(
                        postgres.getJdbcUrl(),
                        "acme_user_app_ddl",
                        "acme_user_app_ddl")
                .defaultSchema("main")
                .locations("com/qlued/pg/schema")
                .failOnMissingLocations(true)
                .load();

        flyway.migrate();

        // Initialize MyBatis.
        Properties properties = new Properties();
        properties.put("db.url", postgres.getJdbcUrl());
        String resource = "com/qlued/pg/schema/mybatis.xml";

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

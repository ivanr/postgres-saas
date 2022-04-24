package com.qlued.pg.schema;

import com.qlued.pg.model.Tenant;
import com.qlued.pg.model.TenantNote;
import org.apache.ibatis.exceptions.PersistenceException;
import org.apache.ibatis.session.SqlSession;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.io.IOException;

import static org.junit.jupiter.api.Assertions.assertThrows;

public class TestPermissions extends AbstractDatabaseTest {

    private final static String RLS_KEY_ID = "app.1";

    private final static String RLS_KEY = "1234";

    private final static String T1_ID = "0000017f-c588-d0cf-ecde-ccc5ec98757b";

    private final static String T2_ID = "0000017f-c5da-3736-7853-007773aee4d5";

    @BeforeAll
    public static void init() throws IOException {
        AbstractDatabaseTest.init();

        // Create tenants.
        try (SqlSession session = adminSessionFactory.openSession()) {
            TestMapper mapper = session.getMapper(TestMapper.class);

            mapper.insertTenant(new Tenant(T1_ID, "T1"));
            mapper.insertTenant(new Tenant(T2_ID, "T2"));

            session.commit(true);
        }
    }

    @Test
    public void createTenantNote() {
        try (SqlSession session = tenantSessionFactory.openSession()) {
            TestMapper mapper = session.getMapper(TestMapper.class);
            mapper.setTenantId(T1_ID, RLS_KEY_ID, RLS_KEY);
            mapper.insertNote(new TenantNote(T1_ID, "T1:N1"));
        }
    }

    @Test
    public void injectNoteIntoAnotherTenant() {
        // One tenant attempts to create a note attached to some other tenant.
        assertThrows(PersistenceException.class, () -> {
            try (SqlSession session = tenantSessionFactory.openSession()) {
                TestMapper mapper = session.getMapper(TestMapper.class);
                mapper.setTenantId(T1_ID, RLS_KEY_ID, RLS_KEY);
                mapper.insertNote(new TenantNote(T2_ID, "T1:N2"));
            }
        });
    }
}

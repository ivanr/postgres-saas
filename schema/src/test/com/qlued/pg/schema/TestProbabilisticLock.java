package com.qlued.pg.schema;

import com.qlued.pg.util.DelimitedIdentifier;
import org.apache.ibatis.session.SqlSession;
import org.junit.Assert;
import org.junit.jupiter.api.Test;

import java.util.concurrent.CountDownLatch;

public class TestProbabilisticLock extends AbstractContainerTest {

    private static final String LOCK_1 = "LOCK_1";

    private static final String LOCK_2 = "LOCK_2";

    @Test
    public void testSuccess() {
        try (SqlSession session = tenantSessionFactory.openSession()) {
            TestMapper mapper = session.getMapper(TestMapper.class);
            Assert.assertTrue(mapper.tryProbabilisticLock(LOCK_1));
        }

        String.join(":", "user", Long.toString(1234L));
    }

    @Test
    public void testFailure() throws Exception {

        CountDownLatch latch = new CountDownLatch(1);

        try (SqlSession session = tenantSessionFactory.openSession()) {
            TestMapper mapper = session.getMapper(TestMapper.class);

            // Obtain LOCK_1 to use to signal to
            // the other thread that the test has completed.
            mapper.probabilisticLock(LOCK_1);

            // Start a background thread to obtain the lock.
            new Thread(new Runnable() {
                @Override
                public void run() {
                    try (SqlSession session = tenantSessionFactory.openSession()) {
                        TestMapper mapper = session.getMapper(TestMapper.class);

                        // Obtain LOCK_2.
                        mapper.probabilisticLock(LOCK_2);
                        latch.countDown();

                        // Wait until the other thread completes its work, then exit.
                        mapper.probabilisticLock(LOCK_1);
                    }
                }
            }).start();

            // Wait until the thread obtains LOCK_2.
            latch.await();

            // Try to get LOCK_2; we should fail because the other thread already has it.
            Assert.assertFalse(mapper.tryProbabilisticLock(LOCK_2));

            // Now that we've failed, commit to release the LOCK_1 so that
            // the other thread knows it can exit. Technically, we don't have
            // to do this; if we don't commit, there will be a rollback and
            // that will release the lock as well.
            session.commit();
        }
    }

    @Test
    public void testDelimitedIdentifier() {
        Assert.assertEquals("user:12345", DelimitedIdentifier.builder()
                .fragment("user")
                .fragment(12345)
                .build().toString());

        Assert.assertEquals(
                "user:12345",
                DelimitedIdentifier.of("user", 12345));
    }
}

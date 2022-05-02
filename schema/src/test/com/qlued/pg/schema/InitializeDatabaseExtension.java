package com.qlued.pg.schema;

import org.junit.jupiter.api.extension.AfterAllCallback;
import org.junit.jupiter.api.extension.BeforeAllCallback;
import org.junit.jupiter.api.extension.ExtensionContext;

// Junit 5 Guide: Extensions
// https://junit.org/junit5/docs/current/user-guide/#extensions

// A Guide to JUnit 5 Extensions
// https://www.baeldung.com/junit-5-extensions

public class InitializeDatabaseExtension implements AfterAllCallback, BeforeAllCallback, ExtensionContext.Store.CloseableResource {

    @Override
    public void beforeAll(final ExtensionContext context) {
        //System.out.println("initialize-database: before-all");
    }

    @Override
    public void close() {
        //System.out.println("initialize-database: close");
    }

    @Override
    public void afterAll(ExtensionContext context) {
        //System.out.println("initialize-database: after-all");
    }
}
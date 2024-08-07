
# Documentation

## Users and Tenants

Users and tenants exist independently; this model enables us to support 
a community-style product (e.g., GitHub et al.) as well as the traditional
approach where users belong to tenants. Even in situations where the latter
approach is desired, the  decoupling of users from tenants enables us to support
cross-tenant access, for example for support purposes. Or the independent
consultant use case.

Actually, the model consists of three objects: users, tenants, and tenant-users.
With the introduction of tenant-user we enable clean separation of concerns
and data ownership.

Supporting a data model such as this one is more work, with most effort needed
to answer two questions: 1) do user events belong to a tenant and 2) what happens
to a user account when a tenant is deleted? We solve this with an optional binding
of users to tenants. If a user account is created via a tenant invitation, it's
marked as belonging to the tenant.

A hierarchy of tenants is also supported, with two main use cases in mind: 1) unified
billing and 2) wholesale/reseller model, where a tenant is able to create and own
other tenant accounts.

## Bloat

Useful to clear bloat from a table, without having to drop it (which may have various
negative implications). Getting a lock may be difficult if the table is very busy.

  LOCK TABLE queue IN EXCLUSIVE MODE;
  CREATE TABLE queue_tmp AS TABLE queue;
  TRUNCATE TABLE queue;
  INSERT INTO queue SELECT * FROM queue_tmp;
  DROP TABLE queue_tmp;

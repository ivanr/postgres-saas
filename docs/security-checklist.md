# Database Security Checklist

## Coding

- Use parameterised queries at application level
- Use parameterised queries in stored procedures
- Airgap external data when writing dynamic SQL
- Stream query results to avoid memory overload
- Limit external control over database operations
- Monitor code for correct and incorrect usage
- Encrypt sensitive and high-value data

## Privilege Separation and Tenant Partitioning

- Use multiple database users and practice the principle of least privilege
- Use stored procedures to provide controlled privileged access
- Use appropriate multitenant isolation (separate databases or schemas, or multitenancy)
- Use row-level security in a multitenant database
- Tag data with tenant identities

## Configuration

- Secure access to the database with strong authentication
- Secure database network traffic with encryption
- Restrict network access to the database server
- Remove or disable unnecessary default database accounts and functionality

# Monitoring and Maintenance

- Monitor failed queries
- Monitor successful and failed authentication
- Enable audit logging
- Take extra care when running queries manually
- Todo: Monitor tenant and individual user usage

# Infrastructure

- Encrypt database server filesystem
- Encrypt data at database level if supported
- Design a backup and recovery strategy
- Encrypt database backups
- Ensure physical security

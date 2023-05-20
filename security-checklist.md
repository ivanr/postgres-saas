# Database Security Checklist

## Coding

- Use parameterised queries at application level
- Use parameterised queries in stored procedures
- Airgap external data when writing dynamic SQL
- Monitor for code for correct and incorrect usage
- Encrypt sensitive and high-value data

## Privilege Partitioning

- Use multiple database users and practice the principle of least privilege
- Use stored procedures to provide controlled privileged access
- Use separate databases for strong isolation
- Use appropriate multitenant isolation
- Use row-level security with a multitenant database
- Tag data with tenant identities

## Configuration

- Secure access to the database with strong authentication
- Secure database network traffic with encryption
- Restrict network access to the database server
- Remove default unnecessary database accounts, functionality, and objects

# Monitoring

- Enable audit logging
- Monitor for failed authentication and failed queries

# Infrastructure

- Encrypt database server filesystem
- Design a backup and recovery strategy
- Encrypt database backups
- Ensure physical security

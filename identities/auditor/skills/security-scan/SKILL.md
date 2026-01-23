# Security Scan Skill

Automated and manual security analysis techniques.

## Scan Types

### Static Analysis (SAST)
- Review source code for vulnerabilities
- Check for hardcoded secrets
- Identify insecure patterns
- Analyze dependencies

### Configuration Review
- Check security headers
- Review authentication settings
- Verify encryption configurations
- Audit access controls

### Dependency Audit
- Check for outdated packages
- Identify known CVEs
- Review transitive dependencies
- Check license compliance

## Common Vulnerability Patterns

### Injection
```
# SQL Injection
query = "SELECT * FROM users WHERE id = " + user_input  # BAD
query = "SELECT * FROM users WHERE id = ?"  # GOOD

# Command Injection
os.system("echo " + user_input)  # BAD
subprocess.run(["echo", user_input])  # GOOD
```

### Authentication
- Weak password requirements
- Missing rate limiting
- Insecure session management
- Hardcoded credentials

### Data Exposure
- Sensitive data in logs
- Unencrypted storage
- Verbose error messages
- Debug endpoints in production

## Severity Levels
- **Critical**: Immediate exploitation, full compromise
- **High**: Significant impact, likely exploitable
- **Medium**: Limited impact or requires conditions
- **Low**: Minor issues, best practice violations

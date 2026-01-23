# Code Reviewer Skill

Thorough code review for quality, security, and maintainability.

## Usage
Apply this skill when reviewing pull requests, code changes, or performing audits.

## Review Checklist
1. **Correctness** - Does the code do what it claims?
2. **Security** - No injection, XSS, auth bypass, secrets exposure
3. **Performance** - No N+1 queries, memory leaks, blocking operations
4. **Readability** - Clear naming, appropriate comments, consistent style
5. **Testing** - Adequate test coverage, edge cases handled
6. **Error Handling** - Graceful failures, meaningful error messages

## Output Format
```markdown
## Code Review Summary

### Severity: [Critical|High|Medium|Low]

### Issues Found
- [ ] Issue description (file:line)

### Suggestions
- Improvement idea

### Approved: [Yes/No]
```

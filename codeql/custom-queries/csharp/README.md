# Custom CodeQL Queries for C#

This directory contains custom CodeQL queries to detect specific code quality and security issues in C# projects.

## Available Queries

| Query | ID | Severity | Purpose |
|-------|----|---------|---------| 
| [BadCatchBlock.ql](BadCatchBlock.md) | `cs/generic-exception-without-details` | Warning | Detects poor generic exception handling patterns |

## Quick Reference

### BadCatchBlock.ql
Finds `catch (Exception)` blocks that don't use exception details or rethrow.

**Common Issues Detected:**
- Empty catch blocks
- Generic error messages without exception details  
- Catch blocks that don't reference the exception variable

**Quick Fix:** Use specific exception types or log actual exception information.

## Usage

### GitHub Actions
Automatically runs via `.github/workflows/runcodeqlchecks.yml`

### Local CodeQL CLI
```bash
# Run all custom queries
codeql database analyze <database> ./codeql/custom-queries/csharp/custom-checks.qls

# Run specific query  
codeql database analyze <database> ./codeql/custom-queries/csharp/BadCatchBlock.ql
```

### Configuration
Queries are included via `codeql-config.yml`:
```yaml
queries:
  - uses: ./codeql/custom-queries/csharp/BadCatchBlock.ql
```

## Adding New Queries

1. Create `.ql` file with proper metadata
2. Add documentation using the template format
3. Update `custom-checks.qls` query suite
4. Test with example code patterns
5. Update this README

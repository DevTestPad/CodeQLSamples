# CodeQL Custom Security Checks

This repository contains custom CodeQL queries for C# code analysis, focusing on common security and reliability issues in .NET applications.

This is a POC sample to explore custom CodeQL queries for specific .NET best practice checks.  There is likely room for improvement and the potential for false positives as some of these scenarios can be complex in nature.

To run VS Code analysis for comparison, build with a release configuration
dotnet build -c Release CodeQlSamples.sln

## Overview

These custom queries extend CodeQL's built-in analysis capabilities to detect specific patterns that can lead to security vulnerabilities, resource leaks, and maintainability issues in C# codebases.

## Available Queries

### 🚨 [Generic Exception Handling Issues](codeql/custom-queries/csharp/BadCatchBlock.md)
**Query ID:** `cs/generic-exception-without-details`  
**Severity:** Warning  
**Category:** Maintainability

Detects catch blocks that catch generic `Exception` types but don't properly handle or use the exception information, leading to silent failures and debugging difficulties.

**Common Issues Detected:**
- Empty generic exception catch blocks
- Generic catches that don't log exception details
- Catch blocks that ignore exception information

---

### 🔒 [Resource Disposal Issues](codeql/custom-queries/csharp/MissingDisposeOrClose.md)
**Query ID:** `cs/missing-resource-disposal`  
**Severity:** Warning  
**Category:** Reliability, Maintainability, Security

Identifies variables holding disposable resources (file streams, database connections, network sockets) that are not properly disposed, which can lead to resource leaks and performance issues.

**Resource Types Monitored:**
- **File I/O:** FileStream, StreamReader, StreamWriter, BinaryReader, BinaryWriter
- **Database:** SqlConnection, SqlCommand, SqlDataReader
- **Network:** Socket, TcpClient, UdpClient

---

### ⚡ [Unsafe Dictionary Threading](codeql/custom-queries/csharp/UnsafeDictionaryAccess.md)
**Query ID:** `cs/unsafe-dictionary-threading`  
**Severity:** Warning  
**Category:** Reliability

Detects `Dictionary<TKey,TValue>` usage patterns that are unsafe in multi-threaded scenarios, which can cause data corruption, infinite loops, or application crashes.

**Threading Contexts Detected:**
- Dictionary operations within `Task.Run`, `Thread.Start`, etc.
- Access to specifically named shared Dictionary fields
- Operations not protected by lock statements

---

## Quick Start

### Running the Queries

To run these custom queries against your C# codebase:

```bash
# Run all custom queries
codeql database analyze <database-name> codeql/custom-queries/csharp/custom-checks.qls

# Run a specific query
codeql database analyze <database-name> codeql/custom-queries/csharp/BadCatchBlock.ql
```

### Query Suite

The queries are organized in a query suite file: [`custom-checks.qls`](codeql/custom-queries/csharp/custom-checks.qls)

This suite can be used to run all custom queries together as part of your CI/CD pipeline.

## Repository Structure

```
CodeQLSamples/
├── README.md                           # This file
├── codeql-config.yml                   # CodeQL configuration
├── Program.cs                          # Sample code with issues
├── *.cs                               # Additional sample files
└── codeql/
    └── custom-queries/
        └── csharp/
            ├── BadCatchBlock.ql        # Generic exception handling query
            ├── BadCatchBlock.md        # Detailed documentation
            ├── MissingDisposeOrClose.ql # Resource disposal query
            ├── MissingDisposeOrClose.md # Detailed documentation
            ├── UnsafeDictionaryAccess.ql # Threading safety query
            ├── UnsafeDictionaryAccess.md # Detailed documentation
            ├── custom-checks.qls       # Query suite definition
            └── qlpack.yml             # CodeQL package configuration
```

## Sample Code

This repository includes sample C# code that demonstrates the issues detected by these queries:

- **`Program.cs`** - Main sample demonstrating various patterns
- **`poorexception.cs`** - Bad exception handling examples
- **`MissingDisposeOrClose.cs`** - Resource disposal issues
- **`poordictionaryuse.cs`** - Threading safety problems

## Integration

### GitHub Actions

To integrate these queries into your GitHub Actions workflow:

```yaml
- name: Run CodeQL Analysis
  uses: github/codeql-action/analyze@v3
  with:
    config-file: ./.github/codeql-config.yml
    queries: +security-and-quality,./codeql/custom-queries/csharp/custom-checks.qls
```

### Azure DevOps

For Azure DevOps integration:

```yaml
- task: CodeQL@1
  inputs:
    language: 'csharp'
    queries: './codeql/custom-queries/csharp/custom-checks.qls'
```

## Best Practices

### Exception Handling
- Catch specific exception types rather than generic `Exception`
- Always log exception details including message and stack trace
- Use structured logging with exception objects
- Consider retry logic for transient failures

### Resource Management
- Use `using` statements for all disposable resources
- Implement `IDisposable` properly in custom classes
- Consider dependency injection for resource lifetime management
- Use `ConfigureAwait(false)` in async scenarios

### Threading Safety
- Use `ConcurrentDictionary<TKey,TValue>` for thread-safe operations
- Implement proper locking strategies for shared mutable state
- Consider reader-writer locks for read-heavy workloads
- Design immutable data structures when possible

## Contributing

To add new custom queries:

1. Create a new `.ql` file in `codeql/custom-queries/csharp/`
2. Add comprehensive documentation in a corresponding `.md` file
3. Update the `custom-checks.qls` query suite
4. Add sample code demonstrating the issue
5. Update this README with the new query information

## References

- [CodeQL Documentation](https://codeql.github.com/docs/)
- [CodeQL for C#](https://codeql.github.com/docs/codeql-language-guides/codeql-for-csharp/)
- [Microsoft .NET Security Guidelines](https://learn.microsoft.com/en-us/dotnet/standard/security/)
- [C# Best Practices](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)

## License

This project is provided as sample code for educational and demonstration purposes.
# MissingDisposeOrClose.ql

References  
• IDisposable Interface documentation: https://learn.microsoft.com/en-us/dotnet/api/system.idisposable  
• Using statement documentation: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/using  
• Best practices for IDisposable: https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/implementing-dispose  

**Query ID:** `cs/missing-resource-disposal`  
**Severity:** Warning  
**Category:** Reliability, Maintainability, Security

## What It Does

Detects variables that hold disposable resources (like file streams, database connections, or network sockets) but are not properly disposed of. This can lead to resource leaks, performance issues, and potential security vulnerabilities.

## Problem Pattern

This query identifies local variables that are assigned disposable resources but lack proper cleanup through:
- `using` statements
- Explicit `Dispose()` calls  
- Explicit `Close()` calls
- Being returned (transferring ownership)

## Examples

### ❌ **Bad (Will Be Flagged)**

```csharp
// File stream without disposal
public void ReadFile()
{
    var stream = new FileStream("file.txt", FileMode.Open);  // LEAKED: Not disposed
    // ... use stream ...
    // Missing: stream.Dispose() or using statement
}

// Database connection without disposal
public void QueryDatabase()
{
    var connection = new SqlConnection(connectionString);    // LEAKED: Not disposed
    var command = new SqlCommand("SELECT * FROM Users", connection);  // LEAKED: Not disposed
    // ... use connection and command ...
    // Missing: proper disposal
}

// Network socket without disposal
public void ConnectToServer()
{
    var client = new TcpClient();                           // LEAKED: Not disposed
    client.Connect("localhost", 8080);
    // ... use client ...
    // Missing: client.Close() or client.Dispose()
}
```

### ✅ **Good (Will NOT Be Flagged)**

```csharp
// Using statement (recommended)
public void ReadFileCorrectly()
{
    using (var stream = new FileStream("file.txt", FileMode.Open))
    {
        // ... use stream ...
    } // Automatically disposed
}

// Using declaration (C# 8.0+)
public void ReadFileModern()
{
    using var stream = new FileStream("file.txt", FileMode.Open);
    // ... use stream ...
    // Automatically disposed at end of scope
}

// Explicit disposal
public void ExplicitDisposal()
{
    var stream = new FileStream("file.txt", FileMode.Open);
    try
    {
        // ... use stream ...
    }
    finally
    {
        stream.Dispose();  // Explicitly disposed
    }
}

// Explicit Close call
public void ExplicitClose()
{
    var connection = new SqlConnection(connectionString);
    try
    {
        connection.Open();
        // ... use connection ...
    }
    finally
    {
        connection.Close();  // Explicitly closed
    }
}

// Returning resource (transferring ownership)
public FileStream OpenFile(string path)
{
    return new FileStream(path, FileMode.Open);  // Caller responsible for disposal
}
```

## Detection Logic

The query identifies problematic patterns by:

1. **Finding resource-creating method calls** that return disposable types:
   - `FileStream`, `StreamReader`, `StreamWriter`, `BinaryReader`, `BinaryWriter`
   - `SqlConnection`, `SqlCommand`, `SqlDataReader`
   - `Socket`, `TcpClient`, `UdpClient`

2. **Checking for proper disposal** by looking for:
   - Variables declared within `using` statements
   - Explicit `Dispose()` method calls on the variable
   - Explicit `Close()` method calls on the variable
   - Variables being returned (ownership transfer)

3. **Flagging variables** that lack any of these disposal mechanisms

## Monitored Resource Types

The query currently detects these specific resource types:
- **File I/O:** `FileStream`, `StreamReader`, `StreamWriter`, `BinaryReader`, `BinaryWriter`
- **Database:** `SqlConnection`, `SqlCommand`, `SqlDataReader`
- **Network:** `Socket`, `TcpClient`, `UdpClient`

## Why This Matters

- **Resource Leaks:** Undisposed resources can accumulate and exhaust system resources
- **Performance:** Resource leaks can cause memory pressure and degrade performance
- **File Handles:** Leaked file handles can prevent other processes from accessing files
- **Network Resources:** Leaked connections can exhaust connection pools
- **Security:** Some resources may hold sensitive data that should be explicitly cleared

## Quick Fixes

### Use Using Statements (Recommended)
```csharp
// Traditional using statement
using (var resource = new DisposableResource())
{
    // Use resource
}

// Using declaration (C# 8.0+)
using var resource = new DisposableResource();
// Use resource - automatically disposed at end of scope
```

### Manual Disposal with Try-Finally
```csharp
DisposableResource resource = null;
try
{
    resource = new DisposableResource();
    // Use resource
}
finally
{
    resource?.Dispose();
}
```

### Close Method for Specific Types
```csharp
var connection = new SqlConnection(connectionString);
try
{
    connection.Open();
    // Use connection
}
finally
{
    connection.Close();  // Close is equivalent to Dispose for connections
}
```

## Related Best Practices

- **Always use `using` statements** for disposable resources when possible
- **Implement IDisposable properly** in your own classes that hold unmanaged resources
- **Use `ConfigureAwait(false)`** when awaiting in using blocks to avoid deadlocks
- **Consider using dependency injection** to manage resource lifetimes
- **Prefer `using` declarations** over `using` statements for cleaner code (C# 8.0+)

## Limitations

This query focuses on commonly used disposable types and may not catch:
- Custom IDisposable implementations
- Resources disposed through indirect method calls
- Complex disposal patterns involving multiple variables
- Async disposal patterns (`IAsyncDisposable`)

For comprehensive resource management analysis, consider using additional static analysis tools or extending this query to cover additional resource types specific to your codebase.

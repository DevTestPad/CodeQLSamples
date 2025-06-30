# BadCatchBlock.ql

References 
•  For more information on .NET performance see, 'Improving .NET Application Performance and Scalability': http://msdn.microsoft.com/en
us/library/ms998530.aspx  
•  Why catch(Exception)/empty catch is bad: https://devblogs.microsoft.com/dotnet/why-catchexceptionempty-catch-is-bad/  

**Query ID:** `cs/generic-exception-without-details`  
**Severity:** Warning  
**Category:** Maintainability

## What It Does

Detects catch blocks that catch generic `Exception` types but don't properly handle or use the exception information.

## Problem Pattern

This query flags exception handling anti-patterns where errors are caught but not meaningfully processed, leading to silent failures and debugging difficulties.

## Examples

### ❌ **Bad (Will Be Flagged)**

```csharp
// Empty generic catch
try { DangerousOperation(); }
catch (Exception) { }

// Generic catch with no exception details
try { DangerousOperation(); }
catch (Exception) {
    Console.WriteLine("Something went wrong");
}

// Uses own variables, not the exception
try { DangerousOperation(); }
catch (Exception) {
    string msg = "Error occurred";
    Logger.Log(msg);
}
```

### ✅ **Good (Will NOT Be Flagged)**

```csharp
// Specific exception type
catch (ArgumentNullException ex) {
    Logger.Error($"Invalid argument: {ex.Message}");
}

// Generic catch using exception details
catch (Exception ex) {
    Logger.Error($"Unexpected error: {ex.Message}", ex);
}

// Generic catch with rethrow
catch (Exception ex) {
    Cleanup();
    throw; // Rethrows for caller to handle
}
```

## Detection Logic

1. **Identifies generic Exception catches** - Looks for `catch (Exception)` patterns while excluding specific exception types
2. **Checks for proper handling** - Ensures catch blocks either:
   - Use the exception variable (`ex`, `e`, `exception`, etc.)
   - Contain throw statements (rethrowing)
   - Are not empty

## Why This Matters

- **Silent Failures:** Hidden exceptions make debugging nearly impossible
- **Poor Logging:** Generic messages provide no actionable information
- **Maintenance Issues:** Problems go unnoticed until they cause major failures

## Quick Fix

Replace generic exception handling with one of these patterns:
- **Specific exceptions:** `catch (SpecificException ex)`
- **Proper logging:** Include `ex.Message`, `ex.StackTrace`, or full exception
- **Rethrow:** Use `throw;` to let callers handle unexpected exceptions

## Related Best Practices

- Catch the most specific exception type possible
- Always log exception details for debugging
- Use structured logging with exception objects
- Consider retry logic for transient failures

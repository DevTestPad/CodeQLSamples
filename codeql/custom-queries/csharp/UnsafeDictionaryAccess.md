# UnsafeDictionaryAccess.ql

**Query ID:** `cs/unsafe-dictionary-threading`  
**Severity:** Warning  
**Category:** Reliability

## What It Does

Detects `Dictionary<TKey,TValue>` usage that may be unsafe in multi-threaded scenarios, based on .NET best practices for thread safety.

## Problem Pattern

`Dictionary<TKey,TValue>` is not thread-safe. Concurrent access from multiple threads can cause data corruption, infinite loops, or application crashes. This query identifies potential threading issues with Dictionary access.

## Examples

### ❌ **Bad (Will Be Flagged)**

```csharp
private static Dictionary<string, int> _cache = new Dictionary<string, int>();

public async Task UnsafeAccess()
{
    await Task.Run(() => {
        _cache.Add("key", 1);        // UNSAFE: No locking
        _cache["key2"] = 2;          // UNSAFE: No locking
        var value = _cache["key"];    // UNSAFE: No locking
    });
}

public void ThreadedMethod()
{
    Thread.Start(() => {
        _cache.Remove("key");        // UNSAFE: No locking
    });
}
```

### ✅ **Good (Will NOT Be Flagged)**

```csharp
private static Dictionary<string, int> _cache = new Dictionary<string, int>();
private static readonly object _lock = new object();

// Option 1: Proper locking
public async Task SafeWithLock()
{
    await Task.Run(() => {
        lock (_lock) {
            _cache.Add("key", 1);    // SAFE: Within lock
            _cache["key2"] = 2;      // SAFE: Within lock
        }
    });
}

// Option 2: Use ConcurrentDictionary
private static ConcurrentDictionary<string, int> _concurrentCache = 
    new ConcurrentDictionary<string, int>();

public async Task SafeWithConcurrent()
{
    await Task.Run(() => {
        _concurrentCache.TryAdd("key", 1);     // SAFE: Thread-safe collection
        _concurrentCache["key2"] = 2;          // SAFE: Thread-safe collection
    });
}

// Option 3: Single-threaded usage
public void SingleThreaded()
{
    var localDict = new Dictionary<string, int>();
    localDict.Add("key", 1);               // SAFE: No threading context
}
```

## Detection Logic

1. **Identifies Dictionary operations** - Looks for Add, Remove, indexer access, etc.
2. **Detects multi-threading context** - Checks for:
   - `Task.Run`, `Thread.Start`, async methods
   - Static Dictionary fields (often shared)
   - Method names containing "thread", "async", "concurrent"
3. **Verifies protection** - Ensures operations are either:
   - Within `lock` statements
   - Using `ConcurrentDictionary` instead
   - In single-threaded context

## Microsoft's Recommendations

From the [Dictionary documentation](https://learn.microsoft.com/en-us/dotnet/api/system.collections.generic.dictionary-2?view=net-9.0):

> **Thread Safety**: This type is not thread safe. If multiple threads must access a Dictionary simultaneously, you must:
> - Synchronize access using a lock
> - Use `ConcurrentDictionary<TKey,TValue>` instead

## Quick Fixes

### Use Locking
```csharp
private static readonly object _lock = new object();

lock (_lock)
{
    dictionary.Add(key, value);
    var result = dictionary[key];
}
```

### Use ConcurrentDictionary
```csharp
// Replace Dictionary with ConcurrentDictionary
private static ConcurrentDictionary<string, int> _cache = 
    new ConcurrentDictionary<string, int>();

_cache.TryAdd(key, value);
_cache.TryGetValue(key, out int result);
```

### Use Locks Around All Access
```csharp
// For complex operations, lock the entire sequence
lock (_lock)
{
    if (dictionary.ContainsKey(key))
    {
        dictionary[key] = newValue;
    }
    else
    {
        dictionary.Add(key, defaultValue);
    }
}
```

## Why This Matters

- **Data Corruption:** Concurrent modifications can corrupt internal Dictionary state
- **Infinite Loops:** Hash table corruption can cause infinite loops during lookup
- **Race Conditions:** Check-then-act patterns are not atomic
- **Application Crashes:** Severe corruption can cause exceptions or crashes

## Related Best Practices

- Use `ConcurrentDictionary<TKey,TValue>` for high-concurrency scenarios
- Implement proper locking strategies for shared mutable state
- Consider reader-writer locks for read-heavy workloads
- Design immutable data structures when possible
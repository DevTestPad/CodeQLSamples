# UnsafeDictionaryAccess.ql

References 
•  Generic Dictionary documentation on MSDN: http://msdn.microsoft.com/en-us/library/xfhwa508(v=VS.100).aspx  
•  Microsoft Blog article, 'High CPU in .NET app using a static Generic.Dictionary': https://www.tessferrandez.com/blog/2009/12/21/high
cpu-in-net-app-using-a-static-generic-dictionary.html 

**Query ID:** `cs/unsafe-dictionary-threading`  
**Severity:** Warning  
**Category:** Reliability

## What It Does

Detects specific patterns of `Dictionary<TKey,TValue>` usage that are likely unsafe in multi-threaded scenarios. This query uses a focused approach to minimize false positives by only flagging Dictionary operations in clearly multi-threaded contexts.

## Problem Pattern

`Dictionary<TKey,TValue>` is not thread-safe. Concurrent access from multiple threads can cause data corruption, infinite loops, or application crashes. This query identifies Dictionary operations that occur within explicit threading constructs or access known shared Dictionary fields.

## Examples

### ❌ **Bad (Will Be Flagged)**

```csharp
// Pattern 1: Dictionary operations within Task.Run
private static Dictionary<string, int> _cache = new Dictionary<string, int>();

public async Task UnsafeTaskRun()
{
    await Task.Run(() => {
        _cache.Add("key", 1);        // UNSAFE: Dictionary operation in Task.Run
        _cache["key2"] = 2;          // UNSAFE: Dictionary operation in Task.Run
        var value = _cache["key"];    // UNSAFE: Dictionary operation in Task.Run
    });
}

// Pattern 2: Access to specifically named shared Dictionary fields
private Dictionary<string, object> _sharedCache = new Dictionary<string, object>();
private Dictionary<int, string> _instanceDict = new Dictionary<int, string>();

public void AccessSharedFields()
{
    _sharedCache.Add("test", value);     // UNSAFE: Access to known shared field
    _instanceDict["key"] = "value";      // UNSAFE: Access to known shared field
}

// Pattern 3: Dictionary operations within Thread.Start
public void ThreadedMethod()
{
    new Thread(() => {
        _cache.Remove("key");        // UNSAFE: Dictionary operation in Thread.Start
    }).Start();
}
```

### ✅ **Good (Will NOT Be Flagged)**

```csharp
private static Dictionary<string, int> _cache = new Dictionary<string, int>();
private static readonly object _lock = new object();

// Safe: Dictionary operations within lock statements
public async Task SafeWithLock()
{
    await Task.Run(() => {
        lock (_lock) {
            _cache.Add("key", 1);    // SAFE: Within lock statement
            _cache["key2"] = 2;      // SAFE: Within lock statement
        }
    });
}

// Safe: Using ConcurrentDictionary instead
private static ConcurrentDictionary<string, int> _concurrentCache = 
    new ConcurrentDictionary<string, int>();

public async Task SafeWithConcurrent()
{
    await Task.Run(() => {
        _concurrentCache.TryAdd("key", 1);     // SAFE: Thread-safe collection
        _concurrentCache["key2"] = 2;          // SAFE: Thread-safe collection
    });
}

// Safe: Single-threaded local Dictionary usage
public void SingleThreaded()
{
    var localDict = new Dictionary<string, int>();
    localDict.Add("key", 1);               // SAFE: Not in threading context, not shared field
    localDict["key2"] = 2;                 // SAFE: Local variable access
}

// Safe: Field names that don't match the specific patterns
private Dictionary<string, int> _myCache = new Dictionary<string, int>();

public void RegularFieldAccess()
{
    _myCache.Add("key", 1);                // SAFE: Field name doesn't match flagged patterns
}
```

## Detection Logic

This query uses a focused approach to minimize false positives by only flagging Dictionary operations in specific scenarios:

### What Gets Flagged
1. **Dictionary operations within threading constructs:**
   - `Task.Run(() => { dictionary.Add(...); })`
   - `Thread.Start(() => { dictionary["key"] = value; })`
   - `Task.StartNew(() => { dictionary.Remove(...); })`

2. **Dictionary operations on specific shared field names:**
   - Field names exactly matching `_sharedCache` or `_instanceDict`
   - These are common patterns indicating intentionally shared state

### What Does NOT Get Flagged
- Dictionary operations protected by `lock` statements
- Local Dictionary variables (not fields)
- Dictionary fields with other names (to avoid false positives)
- `ConcurrentDictionary` operations (thread-safe by design)
- Dictionary operations outside of explicit threading constructs

### Detected Operations
The query flags these Dictionary methods when they occur in the above contexts:
- `Add`, `Remove`, `Clear`
- Indexer access: `dictionary[key] = value` or `var value = dictionary[key]`
- `ContainsKey`, `ContainsValue`, `TryGetValue`

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

## Design Philosophy

This query prioritizes **precision over recall** to avoid overwhelming developers with false positives. It only flags Dictionary usage in contexts where threading issues are highly likely:

- **Threading constructs** (`Task.Run`, `Thread.Start`) clearly indicate multi-threaded execution
- **Specific field names** (`_sharedCache`, `_instanceDict`) indicate intentionally shared state
- **Lock detection** ensures properly synchronized access is not flagged

This focused approach means some unsafe Dictionary usage may not be detected, but the flagged issues are very likely to be genuine threading problems.

## Related Best Practices

- Use `ConcurrentDictionary<TKey,TValue>` for high-concurrency scenarios
- Implement proper locking strategies for shared mutable state  
- Consider reader-writer locks for read-heavy workloads
- Design immutable data structures when possible
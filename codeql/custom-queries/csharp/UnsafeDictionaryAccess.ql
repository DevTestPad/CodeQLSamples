/**
 * @name Unsafe Dictionary access in multi-threaded context
 * @description Detects Dictionary<TKey,TValue> usage that may be unsafe in multi-threaded scenarios
 * @kind problem
 * @id cs/unsafe-dictionary-threading
 * @tags reliability
 * @severity warning
 */

import csharp

/**
 * Checks if a method call is on a Dictionary type using simple name matching
 */
predicate isDictionaryCall(MethodCall call) {
  exists(string typeName |
    typeName = call.getQualifier().getType().getName() and
    typeName.matches("Dictionary%") and
    not typeName.matches("ConcurrentDictionary%")
  )
}

/**
 * Checks if a method call is a Dictionary operation that could be unsafe
 */
predicate isDictionaryOperation(MethodCall call) {
  isDictionaryCall(call) and
  call.getTarget().getName().matches([
    "Add", "Remove", "Clear", "set_Item", "get_Item",
    "ContainsKey", "ContainsValue", "TryGetValue"
  ])
}

/**
 * Checks if a method call is within a lock statement
 */
predicate isCallWithinLock(MethodCall call) {
  exists(LockStmt lock | call.getParent*() = lock)
}

/**
 * Checks if a method call is within a Task.Run or similar threading construct
 */
predicate isCallWithinThreadingContext(MethodCall dictCall) {
  exists(MethodCall threadCall |
    threadCall.getTarget().getName().matches(["Run", "Start", "StartNew"]) and
    dictCall.getParent*() = threadCall
  )
}

/**
 * Very specific check: only flag if accessing a field named _sharedCache or _instanceDict
 * This is more precise than trying to detect static fields generically
 */
predicate isAccessingSharedDictionary(MethodCall call) {
  exists(FieldAccess fa |
    fa = call.getQualifier() and
    fa.getTarget().getName().matches(["_sharedCache", "_instanceDict"])
  )
}

from MethodCall dictCall
where
  isDictionaryOperation(dictCall) and
  (
    // ONLY flag these specific unsafe patterns:
    
    // 1. Dictionary access within Task.Run, Thread.Start, etc.
    isCallWithinThreadingContext(dictCall) or
    
    // 2. Access to specific shared dictionary fields we know are problematic
    isAccessingSharedDictionary(dictCall)
  ) and
  // Not protected by locking
  not isCallWithinLock(dictCall)
select dictCall, 
  "Dictionary access in multi-threaded context without proper locking. " +
  "Consider using lock statements or ConcurrentDictionary<TKey,TValue> for thread safety."
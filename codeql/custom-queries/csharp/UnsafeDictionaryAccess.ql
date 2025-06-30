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
    "ContainsKey", "ContainsValue", "TryGetValue", 
    "TryAdd", "TryRemove", "TryUpdate"
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
 * Checks if the dictionary being accessed is a static field (likely shared)
 */
predicate isStaticDictionaryAccess(MethodCall call) {
  exists(FieldAccess fa |
    fa = call.getQualifier() and
    fa.getTarget().isStatic() and
    fa.getTarget().getType().getName().matches("Dictionary%")
  )
}

/**
 * Checks if a method has async/threading keywords
 */
predicate isThreadingMethod(Method m) {
  m.getName().toLowerCase().matches([
    "%async%", "%thread%", "%task%", "%parallel%", "%concurrent%"
  ])
}

from MethodCall dictCall
where
  isDictionaryOperation(dictCall) and
  (
    // Dictionary access within Task.Run, Thread.Start, etc.
    isCallWithinThreadingContext(dictCall) or
    // Access to static dictionary fields (likely shared across threads)
    isStaticDictionaryAccess(dictCall) or
    // Dictionary access in methods with threading keywords
    isThreadingMethod(dictCall.getEnclosingCallable())
  ) and
  // Not protected by locking
  not isCallWithinLock(dictCall)
select dictCall, 
  "Dictionary access in multi-threaded context without proper locking. " +
  "Consider using lock statements or ConcurrentDictionary<TKey,TValue> for thread safety."
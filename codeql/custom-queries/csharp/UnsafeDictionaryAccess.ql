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
 * Checks if a statement is within a lock statement using simple parent checking
 */
predicate isWithinLock(Stmt stmt) {
  exists(LockStmt lock | stmt.getParent*() = lock)
}

/**
 * Checks if a method has threading-related keywords in its name
 */
predicate hasThreadingKeywords(Method m) {
  m.getName().toLowerCase().matches([
    "%thread%", "%async%", "%task%", "%parallel%", "%concurrent%"
  ])
}

/**
 * Checks if there's evidence of multi-threading by looking for Task.Run, Thread.Start, etc.
 */
predicate hasThreadingCalls(RefType container) {
  exists(MethodCall call |
    call.getEnclosingCallable().getDeclaringType() = container and
    (
      call.getTarget().getName().matches(["Run", "Start", "StartNew"]) or
      call.toString().toLowerCase().matches(["%task.run%", "%thread.start%", "%threadpool%"])
    )
  )
}

/**
 * Checks if the container class has static fields that look like shared dictionaries
 */
predicate hasStaticDictionaryFields(RefType container) {
  exists(Field f |
    f.getDeclaringType() = container and
    f.isStatic() and
    f.getType().getName().matches("Dictionary%")
  )
}

/**
 * Determines if there's evidence of multi-threading in the class
 */
predicate hasMultiThreadingEvidence(RefType container) {
  exists(Method m | m.getDeclaringType() = container and hasThreadingKeywords(m)) or
  hasThreadingCalls(container) or
  hasStaticDictionaryFields(container)
}

from MethodCall dictCall, RefType containerClass
where
  isDictionaryOperation(dictCall) and
  containerClass = dictCall.getEnclosingCallable().getDeclaringType() and
  hasMultiThreadingEvidence(containerClass) and
  not isWithinLock(dictCall)
select dictCall, 
  "Dictionary access in multi-threaded context without proper locking. " +
  "Consider using lock statements or ConcurrentDictionary<TKey,TValue> for thread safety."
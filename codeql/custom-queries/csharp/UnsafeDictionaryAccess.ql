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
 * Checks if a type is Dictionary<TKey,TValue>
 */
predicate isDictionaryType(Type t) {
  t.getName().matches("Dictionary%") and
  t.getNamespace().getName() = "System.Collections.Generic"
  or
  exists(TypeAccess ta |
    ta.getTarget().getName().matches("Dictionary%") and
    ta.toString().matches("%Dictionary<%")
  )
}

/**
 * Checks if a method call is a Dictionary mutating operation
 */
predicate isDictionaryMutatingCall(MethodCall call) {
  call.getTarget().getName() in [
    "Add", "Remove", "Clear", "set_Item", 
    "TryAdd", "TryRemove", "TryUpdate"
  ] and
  isDictionaryType(call.getQualifier().getType())
}

/**
 * Checks if a method call is a Dictionary read operation
 */
predicate isDictionaryReadCall(MethodCall call) {
  call.getTarget().getName() in [
    "ContainsKey", "ContainsValue", "TryGetValue", 
    "get_Item", "get_Count", "get_Keys", "get_Values"
  ] and
  isDictionaryType(call.getQualifier().getType())
}

/**
 * Checks if a statement is within a lock block
 */
predicate isWithinLock(Stmt stmt) {
  exists(LockStmt lock | stmt.getParent*() = lock.getBody())
}

/**
 * Checks if a method has threading-related attributes or keywords
 */
predicate hasThreadingIndicators(Method m) {
  m.getName().toLowerCase().matches([
    "%thread%", "%async%", "%concurrent%", "%parallel%", "%task%"
  ])
  or
  exists(Attribute attr |
    attr.getTarget() = m and
    attr.getType().getName().matches([
      "%Thread%", "%Async%", "%Task%", "%Concurrent%"
    ])
  )
}

/**
 * Checks if a class has static Dictionary fields (often shared across threads)
 */
predicate isStaticDictionaryField(Field f) {
  f.isStatic() and
  isDictionaryType(f.getType())
}

/**
 * Checks if there's evidence of multi-threading in the same class
 */
predicate hasMultiThreadingEvidence(RefType container) {
  exists(Method m | m.getDeclaringType() = container and hasThreadingIndicators(m))
  or
  exists(Field f | f.getDeclaringType() = container and isStaticDictionaryField(f))
  or
  exists(MethodCall call |
    call.getEnclosingCallable().getDeclaringType() = container and
    (
      call.getTarget().getName().matches([
        "Start", "Run", "StartNew", "ContinueWith"
      ]) and
      call.getTarget().getDeclaringType().getName().matches([
        "Thread", "Task", "ThreadPool"
      ])
    )
  )
}

from MethodCall dictCall, RefType containerClass
where
  (isDictionaryMutatingCall(dictCall) or isDictionaryReadCall(dictCall)) and
  containerClass = dictCall.getEnclosingCallable().getDeclaringType() and
  hasMultiThreadingEvidence(containerClass) and
  not isWithinLock(dictCall) and
  // Exclude if using ConcurrentDictionary instead
  not dictCall.getTarget().getDeclaringType().getName().matches("ConcurrentDictionary%")
select dictCall, 
  "Dictionary access in multi-threaded context without proper locking. " +
  "Consider using lock statements or ConcurrentDictionary<TKey,TValue> for thread safety."
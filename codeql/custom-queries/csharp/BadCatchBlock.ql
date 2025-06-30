/**
 * @name Generic exception handler without proper logging
 * @description Finds catch blocks that catch generic exceptions without proper logging or rethrowing
 * @kind problem
 * @id cs/generic-exception-without-logging
 * @tags maintainability
 * @severity warning
 */

import csharp

/**
 * Checks if a statement contains logging calls using simple name matching
 */
predicate hasLoggingCall(Stmt stmt) {
  exists(MethodCall call |
    call.getParent*() = stmt and
    (
      // Check for common logging method names
      call.getTarget().getName().toLowerCase().matches([
        "%log%", "%write%", "%debug%", "%info%", "%warn%", "%error%", 
        "%fatal%", "%trace%", "%print%"
      ])
      or
      // Check for Console class methods by name
      (
        call.getTarget().getDeclaringType().getName() = "Console" and
        call.getTarget().getName().matches(["WriteLine", "Write"])
      )
      or
      // Check for Debug/Trace methods by name
      (
        call.getTarget().getDeclaringType().getName().matches(["Debug", "Trace"]) and
        call.getTarget().getName().matches(["WriteLine", "Write"])
      )
    )
  )
}

/**
 * Checks if the catch block contains a rethrow or new throw
 */
predicate hasThrowStatement(CatchClause catch) {
  exists(ThrowStmt throw | throw.getParent*() = catch.getBlock())
}

/**
 * Checks if this is a generic Exception catch using simple name matching
 */
predicate isGenericExceptionCatch(CatchClause catch) {
  exists(TypeAccess ta |
    ta = catch.getCaughtExceptionType() and
    ta.getTarget().getName() = "Exception"
  )
  or
  // Catch with no specific type
  not exists(catch.getCaughtExceptionType())
}

from CatchClause catch
where
  // Focus on generic Exception catches
  isGenericExceptionCatch(catch)
  and
  // The catch block doesn't have proper error handling
  (
    // Empty catch block
    catch.getBlock().getNumberOfStmts() = 0
    or
    (
      // Has statements but no logging and no rethrowing
      catch.getBlock().getNumberOfStmts() > 0 and
      not hasLoggingCall(catch.getBlock()) and
      not hasThrowStatement(catch)
    )
  )
select catch, 
  "This catch block catches generic 'Exception' but doesn't log the error or rethrow. " +
  "Consider logging the exception details or catching more specific exception types."

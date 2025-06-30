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
 * Checks if a statement or its descendants contain logging calls
 */
predicate hasLoggingCall(Stmt stmt) {
  exists(MethodCall call |
    call.getParent*() = stmt and
    (
      // Common logging methods
      call.getTarget().getName().toLowerCase().matches([
        "%log%", "%write%", "%debug%", "%info%", "%warn%", "%error%", 
        "%fatal%", "%trace%", "%print%"
      ])
      or
      // Console writes (basic logging)
      call.getTarget().getDeclaringType().hasQualifiedName("System.Console")
      or
      // Debug/Trace writes
      call.getTarget().getDeclaringType().hasQualifiedName("System.Diagnostics.Debug") or
      call.getTarget().getDeclaringType().hasQualifiedName("System.Diagnostics.Trace")
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
 * Checks if this is a generic Exception catch
 */
predicate isGenericExceptionCatch(CatchClause catch) {
  // Catches System.Exception specifically
  catch.getCaughtExceptionType().hasQualifiedName("System.Exception")
  or
  // Catches with no specific type (catches everything)
  not exists(catch.getCaughtExceptionType())
  or
  // Catches base Exception class
  catch.getCaughtExceptionType().getName() = "Exception"
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
  "This catch block catches generic exceptions but doesn't log the error or rethrow. " +
  "Consider logging the exception details or catching more specific exception types."

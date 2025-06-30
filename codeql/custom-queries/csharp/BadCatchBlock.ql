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
      // Common logging frameworks and methods
      call.getTarget().getName().toLowerCase().matches([
        "%log%", "%write%", "%debug%", "%info%", "%warn%", "%error%", 
        "%fatal%", "%trace%", "%print%", "%record%", "%report%"
      ])
      or
      // Specific logging types/namespaces
      call.getTarget().getDeclaringType().getName().toLowerCase().matches([
        "%logger%", "%log%", "%ilog%", "%eventlog%", "%trace%", "%debug%"
      ])
      or
      // Console writes (basic logging)
      call.getTarget().getDeclaringType().hasQualifiedName("System.Console")
      or
      // Common logging framework calls
      call.getTarget().getDeclaringType().getNamespace().getName().toLowerCase().matches([
        "%logging%", "%log4net%", "%nlog%", "%serilog%"
      ])
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
 * Checks if the catch block is effectively empty (only comments or trivial statements)
 */
predicate isEffectivelyEmpty(CatchClause catch) {
  catch.getBlock().getNumberOfStmts() = 0
  or
  (
    catch.getBlock().getNumberOfStmts() <= 2 and
    not hasLoggingCall(catch.getBlock()) and
    not hasThrowStatement(catch) and
    not exists(ReturnStmt ret | ret.getParent*() = catch.getBlock())
  )
}

from CatchClause catch
where
  // Focus on generic Exception catches
  (
    // Catches System.Exception specifically
    catch.getCaughtExceptionType().hasQualifiedName("System.Exception")
    or
    // Catches with no specific type (catches everything)
    not exists(catch.getCaughtExceptionType())
    or
    // Catches base Exception class
    catch.getCaughtExceptionType().getName() = "Exception"
  )
  and
  // The catch block doesn't have proper error handling
  (
    isEffectivelyEmpty(catch)
    or
    (
      // Has statements but no logging and no rethrowing
      catch.getBlock().getNumberOfStmts() > 0 and
      not hasLoggingCall(catch.getBlock()) and
      not hasThrowStatement(catch)
    )
  )
  and
  // Exclude catch blocks that are clearly meant to be empty for valid reasons
  not exists(Comment comment |
    comment.getLocation().getFile() = catch.getLocation().getFile() and
    comment.getText().toLowerCase().matches([
      "%intentionally%empty%", "%deliberately%ignore%", "%expected%", 
      "%ignore%", "%suppress%", "%valid%empty%"
    ])
  )
select catch, 
  "This catch block catches generic exceptions but doesn't log the error or rethrow. " +
  "Consider logging the exception details or catching more specific exception types."

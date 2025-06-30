/**
 * @name Empty or poor generic exception handler
 * @description Finds catch blocks that catch generic exceptions without proper handling
 * @kind problem
 * @id cs/poor-generic-exception-handler
 * @tags maintainability
 * @severity warning
 */

import csharp

/**
 * Checks if a statement contains any method calls that look like logging
 */
predicate hasLoggingCall(Stmt stmt) {
  exists(MethodCall call |
    call.getParent*() = stmt and
    call.getTarget().getName().toLowerCase().matches([
      "%log%", "%write%", "%debug%", "%info%", "%warn%", "%error%", 
      "%fatal%", "%trace%", "%print%"
    ])
  )
}

/**
 * Checks if the catch block contains a throw statement
 */
predicate hasThrowStatement(CatchClause catch) {
  exists(ThrowStmt throw | throw.getParent*() = catch.getBlock())
}

/**
 * Simple check for generic exception catches by looking at the variable type name
 */
predicate looksLikeGenericException(CatchClause catch) {
  // Check if the catch clause text contains "Exception" but not specific exception types
  exists(string varType |
    varType = catch.getVariable().getType().getName() and
    varType = "Exception"
  )
  or
  // Catch with no variable (catch everything)
  not exists(catch.getVariable())
}

from CatchClause catch
where
  // Look for generic exception patterns
  looksLikeGenericException(catch)
  and
  // Empty or problematic handling
  (
    // Completely empty catch block
    catch.getBlock().getNumberOfStmts() = 0
    or
    // Small catch block without proper logging or rethrowing
    (
      catch.getBlock().getNumberOfStmts() <= 2 and
      not hasLoggingCall(catch.getBlock()) and
      not hasThrowStatement(catch)
    )
  )
select catch, 
  "This catch block catches generic exceptions but doesn't properly log or rethrow. " +
  "Consider logging the exception details or catching more specific exception types."

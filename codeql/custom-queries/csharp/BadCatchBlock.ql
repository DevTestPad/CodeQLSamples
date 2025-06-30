/**
 * @name Empty or trivial catch block
 * @description Finds catch blocks that are empty or contain only trivial statements without proper error handling
 * @kind problem
 * @id cs/empty-catch-block
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

from CatchClause catch
where
  // Focus on problematic catch blocks
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
  "This catch block is empty or doesn't properly handle exceptions. " +
  "Consider logging the exception details or rethrowing the exception."

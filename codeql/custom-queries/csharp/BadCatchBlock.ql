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
 * Checks if a logging call actually uses exception information
 * by looking for variable access in the arguments
 */
predicate hasMeaningfulLogging(Stmt stmt) {
  exists(MethodCall call |
    call.getParent*() = stmt and
    call.getTarget().getName().toLowerCase().matches([
      "%log%", "%write%", "%debug%", "%info%", "%warn%", "%error%", 
      "%fatal%", "%trace%", "%print%"
    ]) and
    // Check if any argument contains a variable access (likely the exception)
    exists(VariableAccess va | va.getParent*() = call)
  )
}

/**
 * Checks if the catch block contains a throw statement
 */
predicate hasThrowStatement(CatchClause catch) {
  exists(ThrowStmt throw | throw.getParent*() = catch.getBlock())
}

/**
 * Checks if the catch block only contains assignment statements
 * (like: string error = ex.Message; which doesn't actually handle the error)
 */
predicate hasOnlyTrivialAssignments(CatchClause catch) {
  catch.getBlock().getNumberOfStmts() > 0 and
  catch.getBlock().getNumberOfStmts() <= 2 and
  forall(Stmt stmt | stmt.getParent() = catch.getBlock() |
    stmt instanceof AssignExpr or 
    stmt instanceof LocalVariableDeclStmt
  )
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
      not hasMeaningfulLogging(catch.getBlock()) and
      not hasThrowStatement(catch)
    )
    or
    // Catch block with only trivial assignments
    hasOnlyTrivialAssignments(catch)
    or
    // Catch block that has logging but it's just generic messages (no exception details)
    (
      catch.getBlock().getNumberOfStmts() <= 3 and
      hasLoggingCall(catch.getBlock()) and
      not hasMeaningfulLogging(catch.getBlock()) and
      not hasThrowStatement(catch)
    )
  )
select catch, 
  "This catch block doesn't properly handle exceptions. " +
  "Consider logging the actual exception details or rethrowing the exception."

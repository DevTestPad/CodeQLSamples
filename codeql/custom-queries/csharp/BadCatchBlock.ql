/**
 * @name Generic exception catch without using exception details
 * @description Finds catch blocks that catch generic exceptions but don't use the exception information
 * @kind problem
 * @id cs/generic-exception-without-details
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
 * Checks if the catch block uses any variable that was declared in the catch parameter
 * We look for variables named typically like exception parameters (ex, e, exception, etc.)
 */
predicate usesLikelyExceptionVariable(CatchClause catch) {
  exists(VariableAccess va |
    va.getParent*() = catch.getBlock() and
    va.getTarget().getName().toLowerCase().matches(["ex", "e", "exception", "error", "err"])
  )
}

/**
 * Checks if this looks like a generic exception catch by examining the catch clause text
 * This is a heuristic approach since we can't easily get the exact type
 */
predicate looksLikeGenericException(CatchClause catch) {
  // Look for patterns in the source text that suggest generic exception handling
  exists(string catchText |
    catchText = catch.toString().toLowerCase() and
    (
      catchText.matches("%catch%exception%") and
      not catchText.matches("%argumentexception%") and
      not catchText.matches("%invalidoperationexception%") and
      not catchText.matches("%nullreferenceexception%") and
      not catchText.matches("%notimplementedexception%") and
      not catchText.matches("%unauthorizedaccessexception%") and
      not catchText.matches("%filenotfoundexception%") and
      not catchText.matches("%directorynotfoundexception%") and
      not catchText.matches("%timeoutexception%")
    )
  )
  or
  // Catch-all without specifying type
  catch.toString().matches("%catch%(%")
}

from CatchClause catch
where
  // Focus on generic exception catches
  looksLikeGenericException(catch)
  and
  // That don't properly handle the exception
  (
    // Empty catch block
    catch.getBlock().getNumberOfStmts() = 0
    or
    // Non-empty but doesn't use exception details and doesn't rethrow
    (
      catch.getBlock().getNumberOfStmts() > 0 and
      not usesLikelyExceptionVariable(catch) and
      not hasThrowStatement(catch)
    )
  )
select catch, 
  "This catch block catches generic exceptions but doesn't use the exception details or rethrow. " +
  "Consider logging the actual exception information or catching more specific exception types."
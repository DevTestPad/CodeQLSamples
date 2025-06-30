/**
 * @name Empty or unhandled catch block
 * @description Finds catch blocks that catch System.Exception (or all exceptions) and do not log, rethrow, or handle the exception.
 * @kind problem
 * @id cs/bad-catch-block
 * @tags maintainability
 */

from CatchClause cc
where
  // (1) The catch clause catches Exception or nothing (implicit Exception)
  (cc.getExceptionType() instanceof BuiltInType &&
   cc.getExceptionType().getQualifiedName() = "System.Exception") or
  cc.getExceptionType() = null

  // (2) The catch block is empty, or does not use/log/throw the exception variable
  and not exists(
    Call call |
      call.getEnclosingStmt() = cc.getBody() and
      (
        // Logging commonly involves calling a method with the exception variable
        (exists(Expr arg | call.getArgument(arg) and arg.toString().matches("%exception%")))
        // Or, rethrowing the exception
        or (call.getTarget().getName() = "Throw")
      )
  )
select cc,
  "This catch block traps Exception (or all exceptions) but does not log, rethrow, or otherwise handle the exception."

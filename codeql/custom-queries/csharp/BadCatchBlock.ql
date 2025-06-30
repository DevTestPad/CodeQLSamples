/**
 * @name Empty catch block that swallows exceptions
 * @description Finds catch blocks that catch exceptions but do nothing with them
 * @kind problem
 * @id cs/empty-catch-block
 * @tags maintainability
 * @severity warning
 */

import csharp

from CatchClause catch
where
  // Find catch blocks that are empty or nearly empty
  catch.getBlock().getNumberOfStmts() = 0
  or
  (
    // Or catch blocks that only have simple statements but don't use the caught exception
    catch.getBlock().getNumberOfStmts() <= 2 and
    not exists(ThrowStmt throw | throw.getParent+() = catch.getBlock()) and
    not exists(Variable v, VariableAccess access | 
      v = catch.getVariable() and 
      access.getTarget() = v and 
      access.getEnclosingStmt().getParent+() = catch.getBlock()
    )
  )
select catch, "This catch block silently swallows exceptions without handling them properly."

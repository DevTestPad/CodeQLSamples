/**
 * @name Empty catch block that swallows exceptions
 * @description Finds catch blocks that are empty or contain only trivial statements
 * @kind problem
 * @id cs/empty-catch-block
 * @tags maintainability
 * @severity warning
 */

import csharp

from CatchClause catch
where
  // Empty catch block
  catch.getBlock().getNumberOfStmts() = 0
  or
  // Catch block with only a single simple statement that's not a throw
  (
    catch.getBlock().getNumberOfStmts() = 1 and
    not exists(ThrowStmt throw | throw.getParent() = catch.getBlock())
  )
select catch, "This catch block is empty or trivial and swallows exceptions without proper handling."

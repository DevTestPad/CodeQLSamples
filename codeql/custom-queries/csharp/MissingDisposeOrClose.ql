/**
 * @name Missing Dispose or Close call on resource
 * @description Detects variables holding IDisposable resources that are not properly disposed
 * @kind problem
 * @id cs/missing-resource-disposal
 * @tags reliability
 *       maintainability
 *       security
 * @severity warning
 */

import csharp

/**
 * Checks if a type implements IDisposable
 */
predicate implementsIDisposable(Type t) {
  t.getABaseType*().hasQualifiedName("System", "IDisposable")
}

/**
 * Checks if a type has Close method (common for streams, connections, etc.)
 */
predicate hasCloseMethod(Type t) {
  exists(Method m |
    m = t.getAMethod() and
    m.getName() = "Close" and
    m.getNumberOfParameters() = 0
  )
}

/**
 * Checks if a type is a resource that should be disposed/closed
 */
predicate isResourceType(Type t) {
  implementsIDisposable(t) or
  hasCloseMethod(t) or
  // Common resource types that should be disposed
  t.hasQualifiedName("System.IO", ["FileStream", "StreamReader", "StreamWriter", "BinaryReader", "BinaryWriter"]) or
  t.hasQualifiedName("System.Net.Sockets", ["Socket", "TcpClient", "UdpClient"]) or
  // Support both legacy and modern SqlClient packages
  t.hasQualifiedName("System.Data.SqlClient", ["SqlConnection", "SqlCommand", "SqlDataReader"]) or
  t.hasQualifiedName("Microsoft.Data.SqlClient", ["SqlConnection", "SqlCommand", "SqlDataReader"]) or
  t.hasQualifiedName("System.Data", ["IDbConnection", "IDbCommand", "IDataReader"]) or
  t.getName().matches(["%Connection", "%Reader", "%Writer", "%Stream"])
}

/**
 * Checks if a variable is used in a using statement
 */
predicate isInUsingStatement(Variable v) {
  exists(UsingStmt using |
    using.getVariableDeclExpr().getVariable() = v or
    using.getExpr().(VariableAccess).getTarget() = v
  )
}

/**
 * Checks if Dispose is called on a variable
 */
predicate hasDisposeCall(Variable v) {
  exists(MethodCall call |
    call.getQualifier().(VariableAccess).getTarget() = v and
    call.getTarget().getName() = "Dispose"
  )
}

/**
 * Checks if Close is called on a variable
 */
predicate hasCloseCall(Variable v) {
  exists(MethodCall call |
    call.getQualifier().(VariableAccess).getTarget() = v and
    call.getTarget().getName() = "Close"
  )
}

/**
 * Checks if the variable is returned from the method (caller responsibility)
 */
predicate isReturned(Variable v) {
  exists(ReturnStmt ret |
    ret.getExpr().(VariableAccess).getTarget() = v
  )
}

/**
 * Checks if the variable is assigned to a field (may be disposed elsewhere)
 */
predicate isAssignedToField(Variable v) {
  exists(AssignExpr assign |
    assign.getRValue().(VariableAccess).getTarget() = v and
    assign.getLValue() instanceof FieldAccess
  )
}

/**
 * Checks if the variable is passed to another method that might dispose it
 */
predicate isPassedToMethod(Variable v) {
  exists(MethodCall call |
    call.getAnArgument().(VariableAccess).getTarget() = v
  )
}

/**
 * Main query logic
 */
from LocalVariableDecl decl, Variable v
where
  v = decl.getVariable() and
  isResourceType(v.getType()) and
  // Variable is not properly managed
  not isInUsingStatement(v) and
  not hasDisposeCall(v) and
  not hasCloseCall(v) and
  // Exclude cases where resource management responsibility might be elsewhere
  not isReturned(v) and
  not isAssignedToField(v) and
  not isPassedToMethod(v) and
  // Exclude variables that are null or uninitialized
  exists(decl.getInit()) and
  not decl.getInit() instanceof NullLiteral
select decl, 
  "Resource of type '" + v.getType().getName() + "' should be disposed. " +
  "Consider using a 'using' statement or explicitly calling Dispose()."
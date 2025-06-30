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
predicate implementsIDisposable(ValueOrRefType t) {
  t.getABaseType*().hasQualifiedName("System", "IDisposable")
}

/**
 * Checks if a type is a common resource type that should be disposed
 */
predicate isCommonResourceType(ValueOrRefType t) {
  t.hasQualifiedName("System.IO", ["FileStream", "StreamReader", "StreamWriter", "BinaryReader", "BinaryWriter"]) or
  t.hasQualifiedName("System.Net.Sockets", ["Socket", "TcpClient", "UdpClient"]) or
  t.hasQualifiedName("System.Data.SqlClient", ["SqlConnection", "SqlCommand", "SqlDataReader"]) or
  t.hasQualifiedName("Microsoft.Data.SqlClient", ["SqlConnection", "SqlCommand", "SqlDataReader"]) or
  t.hasQualifiedName("System.Data", ["IDbConnection", "IDbCommand", "IDataReader"])
}

/**
 * Checks if a type should be disposed
 */
predicate isResourceType(Type t) {
  exists(ValueOrRefType vt | vt = t |
    implementsIDisposable(vt) or
    isCommonResourceType(vt)
  )
}

/**
 * Checks if a local variable is used in a using statement
 */
predicate isInUsingStatement(LocalVariable v) {
  exists(UsingStmt using |
    using.getAVariableDeclExpr().getVariable() = v
  )
}

/**
 * Checks if Dispose is called on a variable
 */
predicate hasDisposeCall(LocalVariable v) {
  exists(MethodCall call |
    call.getQualifier().(VariableAccess).getTarget() = v and
    call.getTarget().getName() = "Dispose"
  )
}

/**
 * Checks if Close is called on a variable
 */
predicate hasCloseCall(LocalVariable v) {
  exists(MethodCall call |
    call.getQualifier().(VariableAccess).getTarget() = v and
    call.getTarget().getName() = "Close"
  )
}

/**
 * Checks if the variable is returned from the method
 */
predicate isReturned(LocalVariable v) {
  exists(ReturnStmt ret |
    ret.getExpr().(VariableAccess).getTarget() = v
  )
}

/**
 * Checks if the variable is assigned to a field
 */
predicate isAssignedToField(LocalVariable v) {
  exists(AssignExpr assign |
    assign.getRValue().(VariableAccess).getTarget() = v and
    assign.getLValue() instanceof FieldAccess
  )
}

/**
 * Checks if the variable is passed to another method
 */
predicate isPassedToMethod(LocalVariable v) {
  exists(MethodCall call |
    call.getAnArgument().(VariableAccess).getTarget() = v
  )
}

from LocalVariableDeclExpr decl, LocalVariable v
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
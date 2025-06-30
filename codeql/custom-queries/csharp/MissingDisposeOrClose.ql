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
 * Checks if a type name indicates it's a resource that should be disposed
 */
predicate isResourceTypeName(string typeName) {
  typeName.matches([
    "FileStream", "StreamReader", "StreamWriter", "BinaryReader", "BinaryWriter",
    "SqlConnection", "SqlCommand", "SqlDataReader", 
    "Socket", "TcpClient", "UdpClient",
    "%Stream", "%Reader", "%Writer", "%Connection"
  ])
}

/**
 * Checks if a variable declaration is for a resource type
 */
predicate isResourceVariable(VariableDeclarationExpr var) {
  isResourceTypeName(var.getVariable().getType().getName())
}

/**
 * Checks if a variable is used in a using statement
 */
predicate isInUsingStatement(Variable v) {
  exists(UsingStmt using |
    using.getAVariableDeclExpr().getVariable() = v
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
 * Checks if the variable is returned from the method
 */
predicate isReturned(Variable v) {
  exists(ReturnStmt ret |
    ret.getExpr().(VariableAccess).getTarget() = v
  )
}

/**
 * Checks if the variable is assigned to a field
 */
predicate isAssignedToField(Variable v) {
  exists(AssignExpr assign |
    assign.getRValue().(VariableAccess).getTarget() = v and
    assign.getLValue() instanceof FieldAccess
  )
}

from VariableDeclarationExpr decl, Variable v
where
  v = decl.getVariable() and
  isResourceVariable(decl) and
  // Variable is not properly managed
  not isInUsingStatement(v) and
  not hasDisposeCall(v) and
  not hasCloseCall(v) and
  // Exclude cases where resource management responsibility might be elsewhere
  not isReturned(v) and
  not isAssignedToField(v) and
  // Only flag variables that are actually initialized (not just declared)
  exists(decl.getInitializer())
select decl, 
  "Resource of type '" + v.getType().getName() + "' should be disposed. " +
  "Consider using a 'using' statement or explicitly calling Dispose()."
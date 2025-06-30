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
 * Checks if a method call creates a resource that should be disposed
 */
predicate isResourceCreation(MethodCall call) {
  exists(string typeName |
    typeName = call.getTarget().getDeclaringType().getName() and
    typeName.matches([
      "FileStream", "StreamReader", "StreamWriter", "BinaryReader", "BinaryWriter",
      "SqlConnection", "SqlCommand", "SqlDataReader", 
      "Socket", "TcpClient", "UdpClient"
    ]) and
    call.getTarget().getName().matches(["FileStream", "StreamReader", "StreamWriter", "BinaryReader", "BinaryWriter", "SqlConnection", "SqlCommand", "Socket", "TcpClient", "UdpClient"])
  )
}

/**
 * Checks if a variable access is within a using statement
 */
predicate isVariableInUsing(VariableAccess va) {
  exists(UsingStmt using |
    va.getParent*() = using
  )
}

/**
 * Checks if Dispose is called on the same variable
 */
predicate hasDisposeOnVariable(Variable v) {
  exists(MethodCall call |
    call.getQualifier().(VariableAccess).getTarget() = v and
    call.getTarget().getName() = "Dispose"
  )
}

/**
 * Checks if Close is called on the same variable
 */
predicate hasCloseOnVariable(Variable v) {
  exists(MethodCall call |
    call.getQualifier().(VariableAccess).getTarget() = v and
    call.getTarget().getName() = "Close"
  )
}

/**
 * Checks if variable is returned
 */
predicate isVariableReturned(Variable v) {
  exists(ReturnStmt ret |
    ret.getExpr().(VariableAccess).getTarget() = v
  )
}

from LocalVariableDeclStmt declStmt, Variable v
where
  exists(MethodCall resourceCall |
    // Variable is assigned a resource creation call
    declStmt.getAVariableDeclExpr().getVariable() = v and
    declStmt.getAVariableDeclExpr().getInitializer() = resourceCall and
    exists(string typeName |
      typeName = resourceCall.getType().getName() and
      typeName.matches([
        "FileStream", "StreamReader", "StreamWriter", "BinaryReader", "BinaryWriter",
        "SqlConnection", "SqlCommand", "SqlDataReader", 
        "Socket", "TcpClient", "UdpClient"
      ])
    )
  ) and
  // Variable is not properly managed
  not isVariableInUsing(declStmt.getAVariableDeclExpr()) and
  not hasDisposeOnVariable(v) and
  not hasCloseOnVariable(v) and
  not isVariableReturned(v)
select declStmt, 
  "Resource of type '" + v.getType().getName() + "' should be disposed. " +
  "Consider using a 'using' statement or explicitly calling Dispose()."
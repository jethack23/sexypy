(import ast)

(import sexypy.compiler.expr [expr-compile]
        sexypy.compiler.utils *)

(defn stmt-compile [expr]
  (ast.Expr :value (expr-compile expr)
            #** expr.position-info))


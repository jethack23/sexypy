(import ast)

(import sexypy.compiler.expr [expr-compile]
        sexypy.compiler.utils *)

(defn expr-wrapper [sexp]
  (ast.Expr :value (expr-compile sexp)
            #** sexp.position-info))

(defn stmt-compile [sexp]
  (cond (not (paren-p sexp)) (expr-wrapper sexp)
        ;; TODO: statements, imports, control flows, Pattern Matching, function and class definitions, async and await
        True (expr-wrapper sexp)))


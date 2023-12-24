(import ast)

(import sexypy.compiler.expr [expr-compile]
        sexypy.compiler.utils *)

(defn expr-wrapper [sexp]
  (ast.Expr :value (expr-compile sexp)
            #** sexp.position-info))

(defn assign-p [sexp]
  (= sexp.op.name "="))

(defn assign-compile [sexp]
  (setv [op #* targets value] sexp.list)
  (ast.Assign :targets (list (map (fn [x] (expr-compile x :ctx ast.Store)) targets))
              :value (expr-compile value)
              #** sexp.position-info))

(defn stmt-compile [sexp]
  (cond (not (paren-p sexp)) (expr-wrapper sexp)
        (assign-p sexp) (assign-compile sexp)
        ;; TODO: statements, imports, control flows, Pattern Matching, function and class definitions, async and await
        True (expr-wrapper sexp)))


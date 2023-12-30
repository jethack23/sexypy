(import ast)

(import collections [deque])
(import functools [reduce])

(import sexypy.compiler.expr [expr-compile]
        sexypy.compiler.utils *
        sexypy.utils *)

(defn expr-wrapper [sexp]
  (ast.Expr :value (expr-compile sexp)
            #** sexp.position-info))

(defn stmt-compile [sexp [decorator-list None]]
  (cond (isinstance sexp ast.AST) sexp
        True (expr-wrapper sexp)))

(defn stmt-list-compile [sexp-list]
  (reduce (fn [x y] (+ x (if (isinstance y list)
                             y
                             [y])))
          (map stmt-compile sexp-list)
          []))

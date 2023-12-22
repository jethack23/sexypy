(require hyrule *)

(import ast)

(import collections [deque])

(import functools [reduce])

(import sexypy.nodes *

        sexypy.compiler.expr *
        sexypy.compiler.stmt *
        sexypy.compiler.utils *)

(defn ast-compile [sexp-list]
  (list (map (fn [e] (ast.Interactive
                       :body [(stmt-compile e)]))
             sexp-list)))

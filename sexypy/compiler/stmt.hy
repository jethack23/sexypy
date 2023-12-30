(import ast)

(import collections [deque])
(import functools [reduce])

(import sexypy.compiler.expr [expr-compile]
        sexypy.compiler.utils *
        sexypy.utils *)

(defn expr-wrapper [sexp]
  (ast.Expr :value (expr-compile sexp)
            #** sexp.position-info))

(defn do-p [sexp]
  (= (str sexp.op) "do"))

(defn do-compile [sexp]
  (setv [op #* sexps] sexp.list)
  (stmt-list-compile sexps))

(defn augassign-p [sexp]
  (in (str sexp.op) augassignop-dict))

(defn augassign-compile [sexp]
  (setv [op target #* args] sexp.list
        op (get augassignop-dict (str op))
        value (reduce (fn [x y] (ast.BinOp x (op) y
                                           #** sexp.position-info))
                      (map expr-compile args)))
  (ast.AugAssign :target (expr-compile target ast.Store)
                 :op (op)
                 :value value
                 #** sexp.position-info))

(defn del-compile [sexp]
  (setv [op #* args] sexp.list)
  (ast.Delete
    :targets (list (map (fn [x] (expr-compile x ast.Del))
                        args))
    #** sexp.position-info))

(defn import-compile [sexp]
  (setv [_ #* names] sexp.list)
  (ast.Import :names (list (map (fn [x] (ast.alias x.name
                                                   #** x.position-info))
                                names))
              #** sexp.position-info))

(defn importfrom-compile [sexp]
  (setv [_ #* args] sexp.list
        modules (cut args None None 2)
        namess (cut args 1 None 2))
  (lfor [module names] (zip modules namess)
        (ast.ImportFrom :module module.name
                        :names (list (map (fn [x] (ast.alias x.name
                                                             #** x.position-info))
                                          names.list))
                        #** (merge-position-infos
                              module.position-info
                              names.position-info))))

(defn stmt-compile [sexp [decorator-list None]]
  (cond (isinstance sexp ast.AST) sexp
        (not (paren-p sexp)) (expr-wrapper sexp)
        (do-p sexp) (do-compile sexp)
        ;; (assign-p sexp) (assign-compile sexp)
        (augassign-p sexp) (augassign-compile sexp)
        (= (str sexp.op) "del") (del-compile sexp)
        (= (str sexp.op) "pass") (ast.Pass #** sexp.position-info)
        (= (str sexp.op) "import") (import-compile sexp)
        (= (str sexp.op) "from") (importfrom-compile sexp)
        ;; (if-p sexp) (if-stmt-compile sexp)
        ;; while
        ;; for
        ;; break
        ;; continue
        ;; (deco-p sexp) (deco-compile sexp decorator-list)
        ;; (functiondef-p sexp) (functiondef-compile sexp decorator-list)
        ;; (return-p sexp) (return-compile sexp)
        (= (str sexp.op) "global") (global-compile sexp)
        (= (str sexp.op) "nonlocal") (nonlocal-compile sexp)
        ;; (classdef-p sexp) (classdef-compile sexp decorator-list)
        ;; TODO: statements, imports, control flows, Pattern Matching, function and class definitions, async and await
        True (expr-wrapper sexp)))

(defn stmt-list-compile [sexp-list]
  (reduce (fn [x y] (+ x (if (isinstance y list)
                             y
                             [y])))
          (map stmt-compile sexp-list)
          []))

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

(defn deco-p [sexp]
  (= (str sexp.op) "deco"))

(defn deco-compile [sexp decorator-list]
  (setv [op decorator def-statement] sexp.list
        new-deco-list (if (isinstance decorator Bracket)
                          decorator.list
                          [decorator]))
  (stmt-compile def-statement (+ (if decorator-list decorator-list []) new-deco-list)))

(defn return-p [sexp]
  (= (str sexp.op) "return"))

(defn return-compile [sexp]
  (setv [op value] sexp.list)
  (ast.Return :value (expr-compile value)
              #** sexp.position-info))

(defn global-compile [sexp]
  (setv [_ #* args] sexp.list)
  (ast.Global :names (list (map (fn [x] x.name) args))
              #** sexp.position-info))

(defn nonlocal-compile [sexp]
  (setv [_ #* args] sexp.list)
  (ast.Nonlocal :names (list (map (fn [x] x.name) args))
                #** sexp.position-info))

(defn classdef-p [sexp]
  (= (str sexp.op) "class"))

(defn classdef-args-parse [args]
  (setv q (deque args)
        bases []
        keywords [])
  (while q
    (setv arg (q.popleft))
    (if (keyword-arg-p arg)
        (keywords.append (ast.keyword :arg arg.name
                                      :value (expr-compile (q.popleft))
                                      #** arg.position-info))
        (bases.append (expr-compile arg))))
  [bases keywords])

(defn classdef-compile [sexp decorator-list]
  (setv [_ clsname args #*body] sexp.list
        [bases keywords] (classdef-args-parse args))
  (ast.ClassDef
    :name clsname.name
    :bases bases
    :keywords keywords
    :body (stmt-list-compile body)
    :decorator-list (if decorator-list
                        (list (map expr-compile decorator-list))
                        [])
    #** sexp.position-info))

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
        (deco-p sexp) (deco-compile sexp decorator-list)
        ;; (functiondef-p sexp) (functiondef-compile sexp decorator-list)
        (return-p sexp) (return-compile sexp)
        (= (str sexp.op) "global") (global-compile sexp)
        (= (str sexp.op) "nonlocal") (nonlocal-compile sexp)
        (classdef-p sexp) (classdef-compile sexp decorator-list)
        ;; TODO: statements, imports, control flows, Pattern Matching, function and class definitions, async and await
        True (expr-wrapper sexp)))

(defn stmt-list-compile [sexp-list]
  (reduce (fn [x y] (+ x (if (isinstance y list)
                             y
                             [y])))
          (map stmt-compile sexp-list)
          []))

(import ast)

(import collections [deque])
(import functools [reduce])

(import sexypy.compiler.expr [expr-compile]
        sexypy.compiler.utils *)

(defn expr-wrapper [sexp]
  (ast.Expr :value (expr-compile sexp)
            #** sexp.position-info))

(defn do-p [sexp]
  (= sexp.op.name "do"))

(defn do-compile [sexp]
  (setv [op #* sexps] sexp.list)
  (stmt-list-compile sexps))

(defn assign-p [sexp]
  (= sexp.op.name "="))

(defn assign-compile [sexp]
  (setv [op #* targets value] sexp.list)
  (ast.Assign :targets (list (map (fn [x] (expr-compile x :ctx ast.Store)) targets))
              :value (expr-compile value)
              #** sexp.position-info))

(defn if-p [sexp]
  (= sexp.op.name "if"))

(defn if-stmt-compile [sexp]
  (setv [_ test then orelse]
        (if (< (len sexp.list) 4)
            [#* sexp.list None]
            sexp.list)) 
  (ast.If :test (expr-compile test)
          :body (stmt-list-compile [then])
          :orelse (if orelse (stmt-list-compile [orelse]) [])
          #** sexp.position-info))

(defn deco-p [sexp]
  (= sexp.op.name "deco"))

(defn deco-compile [sexp decorator-list]
  (setv [op decorator def-statement] sexp.list
        new-deco-list (if (isinstance decorator Bracket)
                          decorator.list
                          [decorator]))
  (stmt-compile def-statement (+ (if decorator-list decorator-list []) new-deco-list)))

(defn functiondef-p [sexp]
  (= sexp.op.name "def"))

(defn def-args-parse [sexp]
  ;; TODO: annotation
  (setv q (deque sexp.list)
        posonlyargs []
        args []
        kwonlyargs []
        kw-defaults []
        defaults [])
  ;; before starred
  (while (and q (and (not (isinstance (get q 0) Starred))
                     (!= (get q 0) "*")))
    (setv arg (q.popleft))
    (cond (= arg "/") (setv posonlyargs args
                            args [])
          (keyward-arg-p arg) (do (args.append (ast.arg :arg (get arg.name (slice 1 None))
                                                        #** arg.position-info))
                                  (defaults.append (expr-compile (q.popleft))))
          True (args.append (ast.arg :arg arg.name
                                     #** arg.position-info))))
  ;; starred
  (setv vararg (if (and q (isinstance (get q 0) Starred))
                   (do (setv arg (q.popleft))
                       (ast.arg :arg arg.value.name
                                #** arg.position-info))
                   None))
  (when (and q (= (get q 0) "*"))
    (q.popleft))
  ;; before doublestarred
  (while (and q (and (not (isinstance (get q 0) DoubleStarred))))
    (setv arg (q.popleft))
    (if (keyward-arg-p arg)
        (do (kwonlyargs.append (ast.arg :arg (get arg.name (slice 1 None))
                                        #** arg.position-info))
            (kw-defaults.append (expr-compile (q.popleft))))
        (do (kwonlyargs.append (ast.arg :arg arg.name
                                        #** arg.position-info))
            (kw-defaults.append None))))
  ;; doublestarred
  (setv kwarg (if q
                  (do (setv arg (q.popleft))
                      (ast.arg :arg arg.value.name
                               #** arg.position-info))
                  None))
  (ast.arguments :posonlyargs posonlyargs
                 :args args
                 :vararg vararg
                 :kwonlyargs kwonlyargs
                 :kw_defaults kw-defaults
                 :kwarg kwarg
                 :defaults defaults
                 #** sexp.position-info))

(defn functiondef-compile [sexp decorator-list]
  (setv [op fnname args #* body] sexp.list)
  (if (and body (= (get body 0) ":->"))
      (setv [_ returns #* body] body)
      (setv returns None))
  (ast.FunctionDef
    :name fnname.name
    :args (def-args-parse args)
    :body (stmt-list-compile body)
    :decorator-list (if decorator-list
                        (list (map expr-compile decorator-list))
                        [])
    :returns (if returns (expr-compile returns) None)
    #** sexp.position-info))

(defn return-p [sexp]
  (= sexp.op.name "return"))

(defn return-compile [sexp]
  (setv [op value] sexp.list)
  (ast.Return :value (expr-compile value)
              #** sexp.position-info))

(defn stmt-compile [sexp [decorator-list None]]
  (cond (not (paren-p sexp)) (expr-wrapper sexp)
        (do-p sexp) (do-compile sexp)
        (assign-p sexp) (assign-compile sexp)
        (if-p sexp) (if-stmt-compile sexp)
        (deco-p sexp) (deco-compile sexp decorator-list)
        (functiondef-p sexp) (functiondef-compile sexp decorator-list)
        (return-p sexp) (return-compile sexp)
        ;; TODO: statements, imports, control flows, Pattern Matching, function and class definitions, async and await
        True (expr-wrapper sexp)))

(defn stmt-list-compile [sexp-list]
  (reduce (fn [x y] (+ x (if (isinstance y list)
                             y
                             [y])))
          (map stmt-compile sexp-list)
          []))

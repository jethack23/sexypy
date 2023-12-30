(require hyrule *)

(import ast)
(import collections [deque])
(import functools [reduce])

(import
  sexypy.utils *
  sexypy.nodes *
  sexypy.compiler [expr-compile
                   def-args-parse])

(defn return-compile [sexp]
  (setv [_ value] sexp.list)
  (ast.Return :value (expr-compile value)
              #** sexp.position-info))
(print "# return-compile macro must be built-in to define other macros.")

(setv __macro-namespace {"return-compile" return-compile})


(defn define-macro [sexp]
  (setv [op macroname args #* body] sexp.list
        new-name (+ "___macro___" macroname.name)
        def-exp (ast.FunctionDef
                  :name new-name
                  :args (def-args-parse args)
                  :body (macroexpand-then-compile body)
                  :decorator-list []
                  :returns None
                  #** sexp.position-info)
        assign-exp (ast.Assign
                     :targets
                     [(ast.Subscript
                        :value (ast.Name :id "__macro_namespace"
                                         :ctx (ast.Load)
                                         #** sexp.position-info)
                        :slice (ast.Constant :value macroname.value
                                             #** sexp.position-info)
                        :ctx (ast.Store)
                        #** sexp.position-info)]
                     :value (ast.Name :id new-name
                                      :ctx (ast.Load)
                                      #** sexp.position-info)
                     #** sexp.position-info))
  (eval (compile (ast.Interactive :body [def-exp assign-exp])
                 "macro-defining"
                 "single"))
  (print "# macro defined:" (macroname.value.replace "-compile" "") "/" new-name)
  None)

(defn macroexpand [sexp]
  (if (or (not (isinstance sexp Expression))
          (< (len sexp) 1))
      sexp
      (do (setv [op #* operands] sexp.list)
          (cond
            (= (str op) "defmacro")
            (define-macro sexp)

            (in (str op) __macro-namespace)
            (macroexpand ((get __macro-namespace (str op)) #* operands))

            (in (+ (str op) "-compile") __macro-namespace)
            (macroexpand ((get __macro-namespace (+ (str op) "-compile"))
                           sexp))

            True
            (do (setv sexp.list (list (filter (fn [x] (not (is x None)))
                                              (map macroexpand sexp.list))))
                sexp)))))




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

(defn macroexpand-then-compile [sexp-list]
  (stmt-list-compile (filter (fn [x] (not (is x None)))
                             (reduce (fn [rst y] (+ rst (if (isinstance y list)
                                                            y
                                                            [y])))
                                     (map macroexpand sexp-list)
                                     []))))

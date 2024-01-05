(require hyrule *)

(import ast)

(import functools [reduce])

(import
  sxpy.nodes *
  sxpy.compiler [def-args-parse
                 stmt-list-compile])


(setv __macro-namespace {})


(defn define-macro [sexp]
  (setv [op macroname args #* body] sexp.list
        new-name (+ "___macro___" macroname.value)
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
  ;; (print "# macro defined: " new-name)
  None)

(defn macroexpand [sexp]
  (cond (or (isinstance sexp Wrapper)
            (isinstance sexp MetaIndicator))
        (do (setv sexp.value (macroexpand sexp.value))
            sexp)
        
        (and (isinstance sexp Expression) (> (len sexp) 0))
        (do (setv [op #* operands] sexp.list)
            (cond
              (= (str op) "defmacro")
              (define-macro sexp)

              (in (str op) __macro-namespace)
              (macroexpand ((get __macro-namespace (str op)) #* operands))

              True
              (do (setv sexp.list (list (filter (fn [x] (not (is x None)))
                                                (map macroexpand sexp.list))))
                  sexp)))
        True sexp))


(defn macroexpand-then-compile [sexp-list]
  (stmt-list-compile (filter (fn [x] (not (is x None)))
                             (map macroexpand sexp-list))))

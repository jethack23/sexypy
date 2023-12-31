(require hyrule *)

(import ast)
(import collections [deque])
(import itertools [chain])
(import functools [reduce])

(import
  sexypy.utils *
  sexypy.nodes *
  sexypy.parser [parse]
  sexypy.compiler [expr-compile
                   def-args-parse])

(defn return-compile [sexp]
  (setv [_ value] sexp.list)
  (ast.Return :value (expr-compile value)
              #** sexp.position-info))
(print "# return-compile macro must be built-in to define other macros.")

(setv __user__macros {}
      __compile__macros {"return-compile" return-compile})

(defn define-macro [sexp namespace]
  (setv [op macroname args #* body] sexp.list
        new-name (+ "___macro___" macroname.name)
        defexp (ast.FunctionDef
                 :name new-name
                 :args (def-args-parse args)
                 :body (list (map (fn [sexp]
                                    (if (isinstance sexp ast.AST)
                                        sexp
                                        (ast.Expr :value (expr-compile sexp)
                                                  #** sexp.position-info)))
                                  
                                  ((fn [x] (print x) x) (list (map compile-macroexpand
                                                                   (chain #* (map macroexpand body)))))))
                 :decorator-list []
                 :returns None
                 #** sexp.position-info)
        assignexp (ast.Assign
                    :targets
                    [(ast.Subscript
                       :value (ast.Name :id namespace
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
  (print (ast.unparse defexp))
  (eval (compile (ast.Interactive :body [defexp assignexp])
                 (+ new-name " macro-definition in " namespace)
                 "single"))
  (print "# macro defined:" macroname.value "in" namespace)
  [])

(defn macroexpand [sexp]
  (if (or (not (isinstance sexp Expression))
          (< (len sexp) 1))
      sexp
      (do (setv [op #* operands] sexp.list)
          (cond
            (= (str op) "defmacro")
            (define-macro sexp "__user__macros")

            (in (str op) __user__macros)
            (macroexpand ((get __user__macros (str op)) #* operands))

            True
            (do (setv sexp.list (list (filter (fn [x] (not (is x None)))
                                              (map macroexpand sexp.list))))
                sexp)))))

(defn compile-macroexpand [sexp]
  (cond (isinstance sexp ast.AST)
        sexp
        
        (or (not (isinstance sexp Expression))
            (< (len sexp) 1))
        sexp

        True
        (do (setv [op #* operands] sexp.list)
            (cond
              (= (str op) "defmacro")
              (define-macro sexp "__compile__macros")

              (in (str op) __user__macros)
              (macroexpand ((get __user__macros (str op)) #* operands))

              (in (+ (str op) "-compile") __user__macros)
              (macroexpand ((get __user__macros (+ (str op) "-compile"))
                             sexp))

              True
              (do (setv sexp.list (list (filter (fn [x] (not (is x None)))
                                                (map macroexpand sexp.list))))
                  sexp)))))



;; (defn macroexpand-then-compile [sexp-list]
;;   (lfor sexp (filter (fn [x] (not (is x None)))
;;                      (reduce (fn [rst y] (+ rst (if (isinstance y list)
;;                                                     y
;;                                                     [y])))
;;                              (map macroexpand sexp-list)
;;                              []))
;;         (stmt-compile sexp)))

(with [f (open "sexypy/macros.sy" "r")]
  (->> (f.read)
       (parse)
       (map compile-macroexpand)
       (filter (fn [x] x))
       ((fn [x] (for [st x]
                  (eval (compile (ast.Interactive :body [st]) "macro-loading" "single")))))))

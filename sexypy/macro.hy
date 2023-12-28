(require hyrule *)

(import ast)

(import functools [reduce])

(import
  sexypy.nodes *
  sexypy.parser [parse]
  sexypy.compiler [stmt-list-compile
                   expr-compile
                   single-parse])


(setv __macro-namespace {})

(defn define-macro [sexp]
  (setv [op macroname args #* body] sexp.list
        new-name (+ "___macro___" macroname.value)
        sexps [(Paren (Symbol "def" #** op.position-info)
                      (Symbol new-name #** macroname.position-info)
                      args
                      #* body
                      #** sexp.position-info)
               (single-parse (+ "(= (sub __macro-namespace \""
                                macroname.value
                                "\") "
                                new-name
                                ")"))])
  (eval (compile (ast.Interactive :body (stmt-list-compile sexps))
                 "macro-defining"
                 "single"))
  (print "macro defined: " new-name)
  None)

(defn macroexpand [sexp]
  (if (not (isinstance sexp Paren))
      sexp
      (do (setv [op #* operands] sexp.list)
          (cond
            (= (str op) "defmacro")
            (define-macro sexp)

            (in (str op) __macro-namespace)
            ((get __macro-namespace (str op)) #* operands)

            True
            (do (setv sexp.list (list (map macroexpand sexp.list)))
                sexp)))))


(defn macroexpand-then-compile [sexp-list]
  (stmt-list-compile (filter (fn [x] x)
                             (map macroexpand sexp-list))))

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

(defn recursive-unquote [sexp gscope lscope]
  (cond (isinstance sexp UnquoteSplice)
        (eval (compile (ast.Expression :body (expr-compile sexp.value))
                       "macro-unquoting-splice"
                       "eval")
              gscope
              lscope)

        (isinstance sexp Unquote)
        (eval (compile (ast.Expression :body (expr-compile sexp.value))
                       "macro-unquoting"
                       "eval")
              gscope
              lscope)

        (isinstance sexp Expression)
        (do (setv sexp.list
                  (reduce (fn [x y] (+ x (if (isinstance y UnquoteSplice)
                                             (list (recursive-unquote y gscope lscope))
                                             [(recursive-unquote y gscope lscope)])))
                          sexp.list
                          []))
            sexp)

        True
        sexp))

(defn macro-return [sexp gscope lscope]
  (cond (isinstance sexp QuasiQuote)
        (recursive-unquote sexp.value gscope lscope)

        (isinstance sexp Quote)
        sexp.value

        True
        sexp))

(defn return-transform [sexp]
  (cond
    (not (isinstance sexp Expression))
    sexp
    
    (and (isinstance sexp Paren)
         (= (str sexp.op) "return"))
    (do (setv [op value] sexp.list)
        (Paren op
               (Paren (Symbol "macro-return" #** value.position-info)
                      (return-transform value)
                      (single-parse "(globals)")
                      (single-parse "(locals)")
                      #** value.position-info)
               #** sexp.position-info))

    True
    (sexp.__class__ #* (list (map return-transform sexp.list))
                    #** sexp.position-info)))

(defn define-macro [sexp]
  (setv [op macroname args #* body] sexp.list
        new-name (+ "___macro___" macroname.value)
        sexps [(Paren (Symbol "def" #** op.position-info)
                      (Symbol new-name #** macroname.position-info)
                      args
                      #* (list (map return-transform body))
                      #** sexp.position-info)
               (single-parse (+ "(= (sub __macro-namespace \""
                                macroname.value
                                "\") "
                                new-name
                                ")"))])
  (eval (compile (ast.Interactive :body (stmt-list-compile sexps))
                 "macro-defining"
                 "single"))
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

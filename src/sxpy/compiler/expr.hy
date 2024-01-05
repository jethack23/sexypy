(require hyrule *)

(import ast)

(import
  collections [deque]
  functools [reduce])

(import
  sxpy.compiler.literal *
  sxpy.compiler.utils *
  sxpy.utils *)

(defn tuple-p [sexp]
  (= (str sexp.op) ","))

(defn tuple-compile [sexp ctx]
  (setv [op #* args] sexp.list)
  (ast.Tuple :elts (list (map (fn [x] (expr-compile x ctx))
                              args))
             :ctx (ctx)
             #** sexp.position-info))

(defn starred-compile [sexp ctx]
  (ast.Starred :value (expr-compile sexp.value ctx)
               :ctx (ctx)
               #** sexp.position-info))

(defn unaryop-p [sexp]
  (and (in (str sexp.op) unaryop-dict)
       (= (len sexp) 2)))

(defn unaryop-compile [sexp]
  (setv [op operand] sexp.list)
  (ast.UnaryOp ((get unaryop-dict (str op)))
               (expr-compile operand)
               #** sexp.position-info))

(defn binop-p [sexp]
  (and (in (str sexp.op) binop-dict)
       (> (len sexp) 2)))

(defn binop-compile [sexp]
  (setv [op #* args] sexp.list)
  (reduce (fn [x y] (ast.BinOp x ((get binop-dict (str op))) y
                               #** sexp.position-info))
          (map expr-compile args)))

(defn boolop-p [sexp]
  (in (str sexp.op) boolop-dict))

(defn boolop-compile [sexp]
  (setv [op #* args] sexp.list)
  (ast.BoolOp ((get boolop-dict op.name))
              (list (map expr-compile args))
              #** sexp.position-info))

(defn compare-p [sexp]
  (in (str sexp.op) compare-dict))

(defn compare-compile [sexp]
  (setv [op #* args] sexp.list
        [left #* comparators] (map expr-compile
                                   args))
  (ast.Compare :left left
               :ops (lfor i (range (len comparators))
                          ((get compare-dict op.name)))
               :comparators comparators
               #** sexp.position-info))

(defn call-args-parse [given]
  (setv q (deque given)
        args []
        keywords [])
  (while q
    (setv arg (q.popleft))
    (cond  (keyword-arg-p arg)
           (keywords.append (ast.keyword :arg arg.name
                                         :value (expr-compile (q.popleft))
                                         #** arg.position-info))
           (doublestarred-p arg)
           (keywords.append (ast.keyword :value (expr-compile arg.value)
                                         #** arg.position-info))

           True
           (args.append (expr-compile arg))))
  [args keywords])

(defn call-compile [sexp]
  (setv [op #* operands] sexp.list
        op (expr-compile op)
        [args keywords] (call-args-parse operands))
  (ast.Call :func op
            :args args
            :keywords keywords
            #** sexp.position-info))

(defn ifexp-p [sexp]
  (= (str sexp.op) "ife"))

(defn ifexp-compile [sexp]
  (setv [_ test body orelse] sexp.list)
  (ast.IfExp :test (expr-compile test)
             :body (expr-compile body)
             :orelse (expr-compile orelse)
             #** sexp.position-info))

(defn attribute-p [sexp]
  (= (str sexp.op) "."))

(defn attribute-compile [sexp ctx]
  (setv [_ value #* attrs] sexp.list
        rst (expr-compile value ast.Load)
        position-info {#** sexp.position-info})
  (for [attr attrs]
    (setv (get position-info "end_lineno") (get attr.position-info "end_lineno")
          (get position-info "end_col_offset") (get attr.position-info "end_col_offset")
          rst (ast.Attribute :value rst
                             :attr (str attr)
                             :ctx (ast.Load)
                             #** position-info)))
  (setv rst.ctx (ctx))
  rst)

(defn methodcall-p [sexp]
  (.startswith (str sexp.op) "."))

(defn methodcall-compile [sexp]
  (setv [method instance #* operands] sexp.list
        [args keywords] (call-args-parse operands)
        func (ast.Attribute :value (expr-compile instance)
                            :attr (get (str method) (slice 1 None))
                            :ctx (ast.Load)
                            #** (merge-position-infos method.position-info
                                                      instance.position-info)))
  (ast.Call :func func
            :args args
            :keywords keywords
            #** sexp.position-info))

(defn namedexpr-p [sexp]
  (= (str sexp.op) ":="))

(defn namedexpr-compile [sexp]
  (setv [_ target value] sexp.list)
  (ast.NamedExpr :target (expr-compile target
                                       :ctx ast.Store)
                 :value (expr-compile value)
                 #** sexp.position-info))

(defn subscript-p [sexp]
  (= (str sexp.op) "sub"))

(defn subscript-compile [sexp ctx]
  (setv [op value #* slices] sexp.list
        op-pos op.position-info
        rst (reduce (fn [rst slice]
                      (ast.Subscript :value rst
                                     :slice (expr-compile slice)
                                     :ctx (ast.Load)
                                     #** (merge-position-infos
                                           op-pos
                                           slice.position-info)))
                    slices
                    (expr-compile value))
        rst.ctx (ctx))
  rst)

(defn parse-comprehensions [generator-body]
  (setv q (deque generator-body)
        rst [])
  (while q
    (setv is-async (if (= (q.popleft) "for") 0 1)
          target (expr-compile (q.popleft) :ctx ast.Store)
          _ (q.popleft)
          iter (expr-compile (q.popleft))
          comprehension (ast.comprehension
                          :is-async is-async
                          :target target
                          :iter iter))
    (setv ifs [])
    (while (and q (not (in (str (get q 0)) ["for" "async-for"])))
      (ifs.append (q.popleft)))
    (setv comprehension.ifs (list (map expr-compile (get ifs (slice 1 None 2)))))
    (rst.append comprehension))
  rst)

(defn gen-exp-compile [sexp]
  (setv [elt #* generator-body] sexp)
  (ast.GeneratorExp :elt (expr-compile elt)
                    :generators (parse-comprehensions generator-body)
                    #** sexp.position-info))

(defn def-args-parse [sexp]
  ;; TODO: annotation
  (setv q (deque sexp.list)
        rst (ast.arguments :posonlyargs []
                           #** sexp.position-info)
        args []
        defaults []
        kwonlyargs []
        kw-defaults [])
  
  ;; before starred
  (while (and q (not (.startswith (str (get q 0)) "*")))
    (setv arg (q.popleft))
    (if (= arg "/") (setv rst.posonlyargs args
                          args [])
        (do (setv ast-arg (ast.arg :arg arg.name
                                   #** arg.position-info))
            (when (and q (isinstance (get q 0) Annotation))
              (setv ast-arg.annotation (expr-compile (q.popleft))))
            (args.append ast-arg)
            (when (keyword-arg-p arg)
              (defaults.append (expr-compile (q.popleft)))))))
  (setv rst.args args
        rst.defaults defaults)
  
  ;; starred
  (when (and q (isinstance (get q 0) Starred))
    (setv arg (q.popleft)
          ast-arg (ast.arg :arg arg.value.name
                           #** arg.position-info))
    (when (and q (isinstance (get q 0) Annotation))
      (setv ast-arg.annotation (expr-compile (q.popleft))))
    (setv rst.vararg ast-arg))
  (when (and q (= (get q 0) "*"))
    (q.popleft))
  
  ;; before doublestarred
  (while (and q (and (not (isinstance (get q 0) DoubleStarred))))
    (setv arg (q.popleft)
          ast-arg (ast.arg :arg arg.name
                           #** arg.position-info))
    (when (and q (isinstance (get q 0) Annotation))
      (setv ast-arg.annotation (expr-compile (q.popleft))))
    (kwonlyargs.append ast-arg)
    (kw-defaults.append (if (keyword-arg-p arg)
                            (expr-compile (q.popleft))
                            None)))
  (setv rst.kwonlyargs kwonlyargs
        rst.kw-defaults kw-defaults)
  
  ;; doublestarred
  (when q
    (setv arg (q.popleft)
          ast-arg (ast.arg :arg arg.value.name
                           #** arg.position-info))
    (when (and q (isinstance (get q 0) Annotation))
      (setv ast-arg.annotation (expr-compile (q.popleft))))
    (setv rst.kwarg ast-arg))
  
  rst)

(defn lambda-p [sexp]
  (= (str sexp.op) "lambda"))

(defn lambda-compile [sexp]
  (setv [_ args body] sexp.list)
  (ast.Lambda
    :args (def-args-parse args)
    :body (expr-compile body)
    #** sexp.position-info))

(defn yield-compile [sexp]
  (setv val-dict (if (> (len sexp) 1)
                     {"value" (expr-compile (get sexp 1))}
                     {}))
  (ast.Yield #** val-dict
             #** sexp.position-info))

(defn yield-from-compile [sexp]
  (setv value (get sexp 1))
  (ast.YieldFrom :value (expr-compile value)
                 #** sexp.position-info))

(defn await-compile [sexp]
  (setv [_ value] sexp.list)
  (ast.Await :value (expr-compile value)
             #** sexp.position-info))

(defn f-str-value-compile [sexp]
  (setv format-spec-dict (if (is sexp.format-spec None)
                             {}
                             {"format_spec"
                              (ast.JoinedStr
                                :values [(ast.Constant
                                           :value sexp.format-spec
                                           #** sexp.position-info)]
                                #** sexp.position-info)}))
  (ast.FormattedValue :value (expr-compile sexp.value)
                      :conversion sexp.conversion
                      #** format-spec-dict
                      #** sexp.position-info))

(defn f-string-compile [sexp]
  (setv values sexp.operands
        compiled [])
  (for [[i v] (enumerate values)]
    (if (% i 2)
        (compiled.append (f-str-value-compile v))
        (compiled.append (string-compile v))))
  (ast.JoinedStr :values compiled
                 #** sexp.position-info))

(defn paren-compiler [sexp ctx]
  (cond
    (tuple-p sexp) (tuple-compile sexp ctx)
    (unaryop-p sexp) (unaryop-compile sexp)
    (binop-p sexp) (binop-compile sexp)
    (boolop-p sexp) (boolop-compile sexp)
    (compare-p sexp) (compare-compile sexp)
    (ifexp-p sexp) (ifexp-compile sexp)
    (attribute-p sexp) (attribute-compile sexp ctx)
    (methodcall-p sexp) (methodcall-compile sexp)
    (namedexpr-p sexp) (namedexpr-compile sexp)
    (subscript-p sexp) (subscript-compile sexp ctx)
    
    (and (> (len sexp) 1)
         (in (str (get sexp 1)) ["for" "async-for"]))
    (gen-exp-compile sexp)
    
    (lambda-p sexp) (lambda-compile sexp)
    (= sexp.op "yield") (yield-compile sexp)
    (= sexp.op "yield-from") (yield-from-compile sexp)
    (= sexp.op "await") (await-compile sexp)
    (= sexp.op "f-string") (f-string-compile sexp)
    True (call-compile sexp)))

(defn slice-compile [sexp]
  (setv [_ #* args] sexp.list
        args (deque args)
        args-dict {})
  (when args
    (setv lower (args.popleft))
    (when (and (!= lower "None")
               (!= lower "_"))
      (setv (get args-dict "lower") (expr-compile lower))))
  (when args
    (setv upper (args.popleft))
    (when (and (!= upper "None")
               (!= upper "_"))
      (setv (get args-dict "upper") (expr-compile upper))))
  (when args
    (setv step (args.popleft))
    (when (and (!= step "None")
               (!= step "_"))
      (setv (get args-dict "step") (expr-compile step))))

  (ast.Slice #** args-dict
             #** sexp.position-info))

(defn list-comp-compile [sexp]
  (setv [elt #* generator-body] sexp)
  (ast.ListComp :elt (expr-compile elt)
                :generators (parse-comprehensions generator-body)
                #** sexp.position-info))

(defn list-compile [sexp ctx]
  (setv args sexp.list)
  (ast.List :elts (list (map (fn [x] (expr-compile x ctx))
                             args))
            :ctx (ctx)
            #** sexp.position-info))

(defn bracket-compiler [sexp ctx]
  (cond (< (len sexp) 1)
        (list-compile sexp ctx)
        
        (= (str sexp.op) ":")
        (slice-compile sexp)
        
        (and (> (len sexp) 1)
             (in (str (get sexp 1)) ["for" "async-for"]))
        (list-comp-compile sexp)
        
        True (list-compile sexp ctx)))

(defn set-compile [sexp]
  (setv [op #* args] sexp.list)
  (ast.Set :elts (list (map expr-compile args))
           #** sexp.position-info))

(defn dict-compile [sexp]
  (setv elts (reduce (fn [x y] (+ x (if (doublestarred-p y)
                                        [None (expr-compile y.value)]
                                        [(expr-compile y)])))
                     sexp
                     [])
        keys (get elts (slice None None 2))
        values (get elts (slice 1 None 2)))
  (ast.Dict :keys keys
            :values values
            #** sexp.position-info))

(defn dict-comp-compile [sexp]
  (setv [key value #* generator-body] sexp)
  (ast.DictComp :key (expr-compile key)
                :value (expr-compile value)
                :generators (parse-comprehensions generator-body)
                #** sexp.position-info))

(defn set-comp-compile [sexp]
  (setv [elt #* generator-body] sexp.operands)
  (ast.SetComp :elt (expr-compile elt)
               :generators (parse-comprehensions generator-body)
               #** sexp.position-info))

(defn brace-compiler [sexp]
  (cond (< (len sexp) 1)
        (dict-compile sexp)
        
        (and (> (len sexp) 2)
             (in (str (get sexp 2)) ["for" "async-for"]))
        ((if (= (str sexp.op) ",") set-comp-compile dict-comp-compile)
          sexp)
        
        (= (str sexp.op) ",") (set-compile sexp)
        True (dict-compile sexp)))

(defn metaindicator-p [sexp]
  (isinstance sexp MetaIndicator))

(defn metaindicator-compile [sexp]
  (cond (isinstance sexp Quote)
        (expr-compile (sexp.value.generator-expression
                        (isinstance sexp QuasiQuote)))
        
        True
        (raise (ValueError "'unquote' is not allowed here"))))

(defn expr-compile [sexp [ctx ast.Load]]
  (cond (paren-p sexp) (paren-compiler sexp ctx)
        (bracket-p sexp) (bracket-compiler sexp ctx)
        (brace-p sexp) (brace-compiler sexp)
        (isinstance sexp Annotation) (expr-compile sexp.value)
        (starred-p sexp) (starred-compile sexp ctx)
        (constant-p sexp) (constant-compile sexp)
        (string-p sexp) (string-compile sexp)
        (metaindicator-p sexp) (metaindicator-compile sexp)
        True (name-compile sexp ctx)))

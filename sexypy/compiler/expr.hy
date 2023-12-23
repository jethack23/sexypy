(require hyrule *)

(import ast)

(import
  collections [deque]
  functools [reduce])

(import
  sexypy.compiler.literal *
  sexypy.compiler.utils *)

(defn tuple-p [sexp]
  (= sexp.op.name ","))

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

(setv unaryop-dict {"+" ast.UAdd
                    "-" ast.USub
                    "not" ast.Not
                    "~" ast.Invert})

(defn unaryop-p [sexp]
  (and (in sexp.op.name unaryop-dict)
       (= (len sexp) 2)))

(defn unaryop-compile [sexp]
  (setv [op operand] sexp.list)
  (ast.UnaryOp ((get unaryop-dict op.name))
               (expr-compile operand)
               #** sexp.position-info))

(setv binop-dict {"+" ast.Add
                  "-" ast.Sub
                  "*" ast.Mult
                  "/" ast.Div
                  "//" ast.FloorDiv
                  "%" ast.Mod
                  "**" ast.Pow
                  "<<" ast.LShift
                  ">>" ast.RShift
                  "|" ast.BitOr
                  "^" ast.BitXor
                  "&" ast.BitAnd
                  "@" ast.MatMult})

(defn binop-p [sexp]
  (and (in sexp.op.name binop-dict)
       (> (len sexp) 2)))

(defn binop-compile [sexp]
  (setv [op #* args] sexp.list)
  (reduce (fn [x y] (ast.BinOp x ((get binop-dict op.name)) y
                               #** sexp.position-info))
          (map expr-compile args)))

(setv boolop-dict {"and" ast.And
                   "or" ast.Or})

(defn boolop-p [sexp]
  (in sexp.op.name boolop-dict))

(defn boolop-compile [sexp]
  (setv [op #* args] sexp.list)
  (ast.BoolOp ((get boolop-dict op.name))
              (list (map expr-compile args))
              #** sexp.position-info))

(setv compare-dict {"==" ast.Eq
                    "!=" ast.NotEq
                    "<" ast.Lt
                    "<=" ast.LtE
                    ">" ast.Gt
                    ">=" ast.GtE
                    "is" ast.Is
                    "is-not" ast.IsNot
                    "in" ast.In
                    "not-in" ast.NotIn})

(defn compare-p [sexp]
  (in sexp.op.name compare-dict))

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
    (cond  (keyward-arg-p arg)
           (keywords.append (ast.keyword :arg (get arg.name (slice 1 None))
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

(defn paren-compiler [sexp ctx]
  (cond
    (tuple-p sexp) (tuple-compile sexp ctx)
    (unaryop-p sexp) (unaryop-compile sexp)
    (binop-p sexp) (binop-compile sexp)
    (boolop-p sexp) (boolop-compile sexp)
    (compare-p sexp) (compare-compile sexp)
    True (call-compile sexp)))

(defn list-compile [sexp ctx]
  (setv args sexp.list)
  (ast.List :elts (list (map (fn [x] (expr-compile x ctx))
                             args))
            :ctx (ctx)
            #** sexp.position-info))

(defn bracket-compiler [sexp ctx]
  (list-compile sexp ctx))

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

(defn brace-compiler [sexp]
  (if (= sexp.op ",")
      (set-compile sexp)
      (dict-compile sexp)))

(defn expr-compile [sexp [ctx ast.Load]]
  (cond (paren-p sexp) (paren-compiler sexp ctx)
        (bracket-p sexp) (bracket-compiler sexp ctx)
        (brace-p sexp) (brace-compiler sexp)
        (starred-p sexp) (starred-compile sexp ctx)
        (constant-p sexp) (constant-compile sexp)
        (string-p sexp) (string-compile sexp)
        True (name-compile sexp ctx)))

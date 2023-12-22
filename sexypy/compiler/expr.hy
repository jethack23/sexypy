(import ast)

(import functools [reduce])

(import
  sexypy.compiler.literal *
  sexypy.compiler.utils *)

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

(defn call-compile [sexp]
  (setv [op #* operands] (list (map expr-compile sexp.list))
        [args keywords] (call-args-parse operands))
  (ast.Call op
            args
            keywords
            #** sexp.position-info))

(defn call-args-parse [operands]
  ;; TODO: parse args so that it can read keyword arguments, *args, **kwargs
  [operands []])

(defn paren-compiler [sexp ctx]
  (cond
    (unaryop-p sexp) (unaryop-compile sexp)
    (binop-p sexp) (binop-compile sexp)
    (boolop-p sexp) (boolop-compile sexp)
    True (call-compile sexp)))

(defn list-compile [sexp ctx]
  (ast.List :elts (list (map (fn [x] (expr-compile x ctx))
                             sexp.list))
            :ctx (ctx)
            #** sexp.position-info))

(defn bracket-compiler [sexp ctx]
  (list-compile sexp ctx))

(defn dict-compile [sexp]
  (setv elts (list (map (fn [x] (if (= x "**")
                                    None
                                    (expr-compile x)))
                        sexp.list))
        keys (get elts (slice None None 2))
        values (get elts (slice 1 None 2)))
  (ast.Dict :keys keys
            :values values
            #** sexp.position-info))

(defn brace-compiler [sexp]
  (dict-compile sexp))

(defn expr-compile [sexp [ctx ast.Load]]
  (cond (paren-p sexp) (paren-compiler sexp ctx)
        (bracket-p sexp) (bracket-compiler sexp ctx)
        (brace-p sexp) (brace-compiler sexp)
        (constant-p sexp) (constant-compile sexp)
        (string-p sexp) (string-compile sexp)
        True (name-compile sexp ctx)))

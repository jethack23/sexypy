(import ast)

(import
  sexypy.compiler.literal *
  sexypy.compiler.utils *)

(setv unaryop-dict {"+" ast.UAdd
                    "-" ast.USub
                    "not" ast.Not
                    "~" ast.Invert})

(defn unaryop-p [expr]
  (and (in expr.op.name unaryop-dict)
       (= (len expr) 2)))

(defn unaryop-compile [expr]
  (setv [op operand] expr.list)
  (ast.UnaryOp ((get unaryop-dict op.name))
               (expr-compile operand)
               #** expr.position-info))

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

(defn binop-p [expr]
  (and (in expr.op.name binop-dict)
       (> (len expr) 2)))

(defn binop-compile [expr]
  (setv [op #* args] expr.list)
  (reduce (fn [x y] (ast.BinOp x ((get binop-dict op.name)) y
                               #** expr.position-info))
          (map expr-compile args)))

(setv boolop-dict {"and" ast.And
                   "or" ast.Or})

(defn boolop-p [expr]
  (in expr.op.name boolop-dict))

(defn boolop-compile [expr]
  (setv [op #* args] expr.list)
  (ast.BoolOp ((get boolop-dict op.name))
              (list (map expr-compile args))
              #** expr.position-info))

(defn call-compile [expr]
  (setv [op #* operands] (list (map expr-compile expr.list))
        [args keywords] (call-args-parse operands))
  (ast.Call op
            args
            keywords
            #** expr.position-info))

(defn call-args-parse [operands]
  ;; TODO: parse args so that it can read keyword arguments, *args, **kwargs
  [operands []])

(defn paren-compiler [expr]
  (cond
    (unaryop-p expr) (unaryop-compile expr)
    (binop-p expr) (binop-compile expr)
    (boolop-p expr) (boolop-compile expr)
    True (call-compile expr)))

(defn bracket-compiler [expr])

(defn brace-compiler [expr])

(defn expr-compile [expr]
  (cond (paren-p expr) (paren-compiler expr)
        (bracket-p expr) (bracket-compiler expr)
        (brace-p expr) (brace-compiler expr)
        (constant-p expr) (constant-compile expr)
        (string-p expr) (string-compile expr)
        True (name-compile expr)))

(require hyrule *)

(import ast)

(import collections [deque])

(import functools [reduce])

(import sexypy.nodes *)

(defn ast-compile [expr-list]
  (list (map (fn [e] (ast.Interactive
                       :body [(stmt-compile e)]))
             expr-list)))

(defn stmt-compile [expr]
  (ast.Expr :value (expr-compile expr)
            :lineno 0
            :col-offset 0))


(defn expr-compile [expr]
  (cond (paren-p expr) (paren-compiler expr)
        (bracket-p expr) (bracket-compiler expr)
        (brace-p expr) (brace-compiler expr)
        (constant-p expr) (constant-compile expr)
        (string-p expr) (string-compile expr)
        True (name-compile expr)))

(defn paren-p [expr]
  (isinstance expr Paren))

(defn paren-compiler [expr]
  (cond
    (unaryop-p expr) (unaryop-compile expr)
    (binop-p expr) (binop-compile expr)
    (boolop-p expr) (boolop-compile expr)
    True (call-compile expr)))

(defn bracket-p [expr]
  (isinstance expr Bracket))

(defn bracket-compiler [expr])

(defn brace-p [expr]
  (isinstance expr Brace))

(defn brace-compiler [expr])

(defn constant-p [expr]
  (isinstance expr Constant))

(defn constant-compile [constant]
  (ast.Constant :value constant.value
                :lineno 0
                :col-offset 0))

(defn string-p [expr]
  (isinstance expr String))

(defn string-compile [string]
  (setv rst (-> (ast.parse string.value)
                (. body)
                (get 0)
                (. value))
        rst.lineno 0
        rst.col-offset 0)
  rst)

(defn name-compile [symbol [ctx ast.Load]]
  (ast.Name :id symbol.name
            :ctx (ctx)
            :lineno 0
            :col-offset 0))

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
               :lineno 0
               :col-offset 0))

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
                               :lineno 0
                               :col-offset 0))
          (map expr-compile args)))

(setv boolop-dict {"and" ast.And
                   "or" ast.Or})

(defn boolop-p [expr]
  (in expr.op.name boolop-dict))

(defn boolop-compile [expr]
  (setv [op #* args] expr.list)
  (ast.BoolOp ((get boolop-dict op.name))
              (list (map expr-compile args))
              :lineno 0
              :col-offset 0))

(defn call-compile [expr]
  (setv [op #* operands] (list (map expr-compile expr.list))
        [args keywords] (call-args-parse operands))
  (ast.Call op
            args
            keywords
            :lineno 0
            :col-offset 0))

(defn call-args-parse [operands]
  ;; TODO: parse args so that it can read keyword arguments, *args, **kwargs
  [operands []])

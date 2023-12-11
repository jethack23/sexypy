(require hyrule *)

(import ast)

(import collections [deque])

(import nodes *)

(defn ast-compile [expr-list]
  (list (map (fn [e] (ast.Interactive
                       :body [(stmt-compile e)]))
             expr-list)))

(defn stmt-compile [expr]
  (ast.Expr :value (expr-compile expr)
            :lineno 0
            :col-offset 0))

(defn expr-compile [expr]
  (cond 
    (constant-p expr) (const-compile expr)

    (unaryop-p expr) (unary-compile expr)
    
    True
    (binop-compile expr)))

(defn constant-p [expr]
  (isinstance expr Constant))

(defn const-compile [constant]
  (ast.Constant :value constant.value
                :lineno 0
                :col-offset 0))

(setv unaryop-dict {"+" ast.UAdd
                    "-" ast.USub
                    "not" ast.Not
                    "~" ast.Invert})

(defn unaryop-p [expr]
  (and (in expr.op.name unaryop-dict)
       (= (len expr) 2)))

(defn unary-compile [expr]
  (ast.UnaryOp ((get unaryop-dict expr.op.name))
               (expr-compile (get expr.list 1))
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

(defn binop-compile [expr]
  (setv 
    q (deque expr.list)
    op (get binop-dict (. (q.popleft) name))
    rst (expr-compile (q.popleft)))
  (while q
    (setv rst (ast.BinOp rst (op) (expr-compile (q.popleft))
                         :lineno 0
                         :col-offset 0)))
  rst)





;(print (ast.dump (get (ast-compile (parse "(+ 2 -1)")) 0) :indent 4))


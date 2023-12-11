(require hyrule *)

(import ast)

(import collections [deque])

(defclass Node []
  (defn __init__ [self #* args #** kwargs]
    (setv self.lineno 0)
    (for [[k v] (kwargs.items)]
      (setv (get self.__dict__ k) v))))

(defclass Expression [Node]
  (defn __init__ [self [tokens None] #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.list (if tokens tokens []))
    None)

  (defn append [self t]
    (.append self.list t))

  (defn __repr__ [self [depth 0]]
    (+ "Expr("
       (.join ", " (lfor e self.list (repr e)))
       ")"))

  (defn __iter__ [self]
    (iter self.list))

  (defn __getitem__ [self idx]
    (get self.list idx))

  (defn __len__ [self]
    (len self.list))

  (defn [property] op [self]
    (get self.list 0))

  (defn [property] operands [self]
    (get self.list (slice 1 None))))

(defmacro def-exp-by-type [type]
  `(defclass ~type [Expression]
     (defn __repr__ [self [depth 0]]
       (+ ~(str type)
          "("
          (.join ", " (lfor e self.list (repr e)))
          ")"))))

(def-exp-by-type Paren)
(def-exp-by-type Bracket)
(def-exp-by-type Brace)

(defclass Symbol [Node]
  (defn __init__ [self name #** kwargs]
    (.__init__ (super #** kwargs))
    (setv self.name name)
    None)

  (defn __repr__ [self]
    (+ "Sym("
       self.name
       ")"))

  (defn __eq__ [self other]
    (= self.name other)))

(defclass Constant [Node]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super #** kwargs))
    (setv self.value value)
    None)

  (defn __repr__ [self]
    (+ "Const("
       (str self.value)
       ")")))

(setv open-brackets "({["
      close-brackets ")}]")

;;; tokenizer for future which aware of lienno and offset
(defn tokenizer [src]
  (setv lines (.split src "\n")
        tokens (deque []))
  (for [[lineno line] (enumerate lines :start 1)]))

(defn pad-brackets [txt]
  (setv rst txt)
  (for [c open-brackets]
    (setv rst (.replace rst c (+ c " "))))
  (for [c close-brackets]
    (setv rst (.replace rst c (+ " " c " "))))
  rst)

(defn simple-tokenizer [src]
  (deque (.split (pad-brackets src))))

(defn onlydigitp [s]
  (all (lfor d s (<= "0" d "9"))))

(defn floatp [s]
  (setv dot-seperated (.split s "."))
  (and (< (len dot-seperated 3))
       (all (lfor t dot-seperated (onlydigitp t)))))

(defn parse [src]
  (setv tokens (simple-tokenizer src)
        stack []
        rst [])
  (for [t tokens]
    (cond (in t ")]}") (do (setv e (stack.pop))
                        (if stack
                            (.append (get stack -1) e)
                            (.append rst e)))
          (= t "(") (stack.append (Paren))
          (= t "[") (stack.append (Bracket))
          (= t "{") (stack.append (Brace))
          True (.append (if stack (get stack -1) rst) (token-parse t))))
  rst)

(defn token-parse [token]
  (cond (and (> (len token) 1) (in (get token 0) "+-")) (unary-op-parse token)
        (onlydigitp token) (Constant (int token))
        (floatp token) (Constant (float token))
        True (Symbol token)))

(defn unary-op-parse [token]
  (setv stack []
        idx 0)
  (while (in (get token idx) "+-")
    (stack.append (get token idx))
    (+= idx 1))
  (setv rst (token-parse (get token (slice idx None))))
  (while stack
    (setv rst (Paren [(Symbol (stack.pop)) rst])))
  rst)

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

(when (= __name__ "__main__")
  (defn run-ast [stl]
    (print "\npython translation")
    (print (.join "\n" (list (map str (map ast.unparse stl)))))
    (print "\nresult")
    (for [st stl]
      (eval (compile st "" "single"))))
  (while True
    (setv st (ast-compile (parse (input "calculate > "))))
    (run-ast st)))

(require hyrule *)

(import ast)

(import collections [deque])

;;; nodes.hy
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
    (iter self.list)))

(defclass Symbol [Node]
  (defn __init__ [self name #** kwargs]
    (.__init__ (super #** kwargs))
    (setv self.name name)
    None)

  (defn __repr__ [self]
    (+ "Sym("
       self.name
       ")")))

(defclass Constant [Node]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super #** kwargs))
    (setv self.value value)
    None)

  (defn __repr__ [self]
    (+ "Const("
       (str self.value)
       ")")))


;;; parser.hy
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

(defn categorize [token]
  (cond (onlydigitp token) (Constant (int token))
        (floatp token) (Constant (float token))
        True (Symbol token)))

(defn parse [src]
  (setv tokens (simple-tokenizer src)
        stack []
        rst [])
  (for [t tokens]
    (cond (= t ")") (do (setv e (stack.pop))
                        (if stack
                            (.append (get stack -1) e)
                            (.append rst e)))
          (= t "(") (stack.append (Expression))
          True (.append (get stack -1) (categorize t))))
  rst)

;;; compile.hy
(defn const-compile [constant]
  (ast.Constant :value constant.value
                :lineno 0
                :col-offset 0))

(defn binop-compile [expr]
  (setv op-dict {"+" ast.Add
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
                 "@" ast.MatMult}
        q (deque expr.list)
        op (get op-dict (. (q.popleft) name))
        rst (recur-compile (q.popleft)))
  (while q
    (setv rst (ast.BinOp rst (op) (recur-compile (q.popleft))
                         :lineno 0
                         :col-offset 0)))
  rst)

(defn recur-compile [expr]
  (cond (isinstance expr Constant)
        (const-compile expr)
        
        True
        (binop-compile expr)))

(defn expr-compile [expr]
  (ast.Expr :value (recur-compile expr)
            :lineno 0
            :col-offset 0))

(defn ast-compile [expr-list [mode "single"]]
  (list (map (fn [e] (ast.Interactive
                       :body [(expr-compile e)]))
             expr-list)))

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

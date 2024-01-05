(require hyrule *)

(defclass Node []
  (defn __init__ [self #* args #** kwargs]
    (setv self.lineno 0
          self.col-offset 0
          self.end-lineno 0
          self.end-col-offset 0)
    (for [[k v] (kwargs.items)]
      (setv (get self.__dict__ k) v)))

  (defn update-dict [self key value]
    (setv (get self.__dict__ key) value))

  (defn [property] position-info [self]
    {"lineno" self.lineno
     "end_lineno" self.end-lineno
     "col_offset" self.col-offset
     "end_col_offset" self.end-col-offset})

  (defn _generator-expression [self in-quasi]
    (Paren (Symbol self.classname #** self.position-info)
           (self.operands-generate in-quasi)
           #** self.position-info))

  (defn generator-expression [self [in-quasi False]]
    (self._generator-expression in-quasi))

  (defn __eq__ [self other]
    (= (str self) other)))

(defclass Expression [Node]
  (defn __init__ [self #* tokens #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.list (list tokens))
    None)

  (defn append [self t]
    (.append self.list t))

  (defn operands-generate [self in-quasi]
    (lfor sexp self.list (sexp.generator-expression in-quasi)))

  (defn generator-expression [self [in-quasi False]]
    (Paren (Symbol self.classname #** self.position-info)
           #* (self.operands-generate in-quasi)
           #** self.position-info))

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

(setv openings {"Paren" "("
                "Bracket" "["
                "Brace" "{"}
      closings {"Paren" ")"
                "Bracket" "]"
                "Brace" "}"})

(defmacro def-exp-by-type [type]
  `(defclass ~type [Expression]

     (defn __init__ [self #* args #** kwargs]
       (.__init__ (super) #* args #** kwargs)
       (setv self.classname ~(str type)))

     (defn __repr__ [self [depth 0]]
       (+ ~(str type)
          "("
          (.join ", " (lfor e self.list (repr e)))
          ")"))

     (defn __str__ [self]
       (+ (get openings ~(str type))
          (.join " " (lfor e self.list (str e)))
          (get closings ~(str type))))))

(def-exp-by-type Paren)
(def-exp-by-type Bracket)
(def-exp-by-type Brace)

(defclass Wrapper [Node]

  (defn operands-generate [self in-quasi]
    (self.value.generator-expression in-quasi)))

(defclass FStrExpr [Wrapper]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value
          self.classname "FStrExpr")
    None)

  (defn __repr__ [self]
    (+ "FStrExpr("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    (+ "(FStrExpr "
       (str self.value)
       ")"))

  (defn [property] name [self]
    self.value.name)

  (defn update-dict [self key value]
    (setv (get self.__dict__ key) value)
    (.update-dict self.value key value)))

(defclass Annotation [Wrapper]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value
          self.classname "Annotation")
    None)

  (defn __repr__ [self]
    (+ "Ann("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    (+ "^"
       (str self.value)))

  (defn append [self e]
    (.append self.value e))

  (defn [property] name [self]
    self.value.name)

  (defn update-dict [self key value]
    (setv (get self.__dict__ key) value)
    (.update-dict self.value key value)))

(defclass Keyword [Wrapper]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value
          self.classname "Keyword")
    None)

  (defn __repr__ [self]
    (+ "Kwd("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    (+ ":"
       (str self.value)))

  (defn [property] name [self]
    self.value.name)

  (defn update-dict [self key value]
    (setv (get self.__dict__ key) value)
    (.update-dict self.value value)))

(defclass Starred [Wrapper]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value
          self.classname "Starred")
    None)

  (defn __repr__ [self]
    (+ "Star("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    (+ "*"
       (str self.value)))

  (defn append [self e]
    (.append self.value e))

  (defn update-dict [self key value]
    (setv (get self.__dict__ key) value)
    (.update-dict self.value key value)))

(defclass DoubleStarred [Wrapper]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value
          self.classname "DoubleStarred")
    None)

  (defn __repr__ [self]
    (+ "DStar("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    (+ "**"
       (str self.value)))

  (defn append [self e]
    (.append self.value e))

  (defn update-dict [self key value]
    (setv (get self.__dict__ key) value)
    (.update-dict self.value key value)))

(defclass Literal [Node]
  (defn operands-generate [self in-quasi]
    (String (+ "\""
               self.value
               "\"")
            #** self.position-info)))

(defclass Symbol [Literal]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value
          self.classname "Symbol")
    None)

  (defn [property] name [self]
    (.replace self.value "-" "_"))

  (defn __repr__ [self]
    (+ "Sym("
       self.value
       ")"))

  (defn __str__ [self]
    self.value))

(defclass String [Literal]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value
          self.classname "String")
    None)

  (defn operands-generate [self in-quasi]
    (String (+ "\""
               (-> self.value
                   (.replace "\\" r"\\")
                   (.replace "\"" r"\""))
               "\"")
            #** self.position-info))

  (defn __repr__ [self]
    (+ "Str("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    self.value))

(defclass Constant [Literal]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value
          self.classname "Constant")
    None)

  (defn __repr__ [self]
    (+ "Const("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    (.replace (str self.value) "\'" "")))

(defclass MetaIndicator [Node]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value)
    None)

  (defn operands-generate [self in-quasi]
    (self.value.operands-generate (isinstance self QuasiQuote))))

(defclass Quote [MetaIndicator]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) value #** kwargs)
    (setv self.classname "Quote")
    None)

  (defn __repr__ [self]
    (+ "Quote("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    (+ "'"
       (str self.value))))

(defclass QuasiQuote [Quote]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) value #** kwargs)
    (setv self.classname "QuasiQuote")
    None)

  (defn __repr__ [self]
    (+ "QuasiQuote("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    (+ "`"
       (str self.value))))

(defclass Unquote [MetaIndicator]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) value #** kwargs)
    (setv self.classname "Unquote")
    None)

  (defn generator-expression [self [in-quasi False]]
    (if in-quasi
        self.value
        (self._generator-expression False)))

  (defn __repr__ [self]
    (+ "Unquote("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    (+ "~"
       (str self.value))))

(defclass UnquoteSplice [Unquote]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) value #** kwargs)
    (setv self.classname "UnquoteSplice")
    None)

  (defn generator-expression [self [in-quasi False]]
    (if in-quasi
        (Starred self.value
                 #** self.position-info)
        (self._generator-expression False)))

  (defn __repr__ [self]
    (+ "UnquoteSplice("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    (+ "~@"
       (str self.value))))

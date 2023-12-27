(require hyrule *)

(defclass Node []
  (defn __init__ [self #* args #** kwargs]
    (for [[k v] (kwargs.items)]
      (setv (get self.__dict__ k) v)))

  (defn update-dict [self key value]
    (setv (get self.__dict__ key) value))  

  (defn [property] position-info [self]
    {"lineno" self.lineno
     "end_lineno" self.end-lineno
     "col_offset" self.col-offset
     "end_col_offset" self.end-col-offset})
  
  (defn indent [self given-indent]
    (+ (* " " (+ 2 (len self.classname))) given-indent))

  (defn position-info-generate [self given-indent]
    (+ "\n"
       (self.indent given-indent)
       "**{\"lineno\" "
       (str self.lineno)
       " \"col_offset\" "
       (str self.col-offset)
       " \"end_lineno\" "
       (str self.end-lineno)
       " \"end_col_offset\" "
       (str self.end-col-offset)
       "}"))

  (defn src-operands-generate [self in-quasi position-info given-indent]
    (+ "\""
       self.value
       "\""))

  (defn _src-to-generate
    [self in-quasi position-info given-indent]
    (+ "("
       self.classname
       " "
       (self.src-operands-generate in-quasi position-info given-indent)
       (if position-info (self.position-info-generate given-indent) "")
       ")"))

  (defn src-to-generate
    [self [in-quasi False] [position-info True] [given-indent ""]]
    (self._src-to-generate in-quasi position-info given-indent))

  (defn __eq__ [self other]
    (= (str self) other)))

(defclass Expression [Node]
  (defn __init__ [self #* tokens #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.list (list tokens))
    None)

  (defn append [self t]
    (.append self.list t))

  (defn src-operands-generate [self in-quasi position-info given-indent]
    (.join (+ "\n" (self.indent given-indent))
           (list (map (fn [x] (x.src-to-generate in-quasi position-info (self.indent given-indent)))
                      self.list))))

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

(defclass Starred [Node]
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

(defclass DoubleStarred [Node]
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

(defclass Symbol [Node]
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

(defclass String [Node]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value
          self.classname "String")
    None)

  (defn src-operands-generate [self in-quasi position-info given-indent]
    (+ "\""
       (-> self.value
           (.replace "\\" r"\\")
           (.replace "\"" r"\""))
       "\""))

  (defn __repr__ [self]
    (+ "Str("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    self.value))

(defclass Constant [Node]
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
  
  (defn src-operands-generate [self in-quasi position-info given-indent]
    (self.value.src-to-generate (isinstance self QuasiQuote)
                                position-info
                                (self.indent given-indent))))

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

  (defn src-to-generate
    [self [in-quasi False] [position-info True] [given-indent ""]]
    (if in-quasi
        (+ (if (isinstance self UnquoteSplice) "*" "") (str self.value))
        (self._src-to-generate False position-info given-indent)))
  
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

  (defn __repr__ [self]
    (+ "UnquoteSplice("
       (repr self.value)
       ")"))

  (defn __str__ [self]
    (+ "~@"
       (str self.value))))

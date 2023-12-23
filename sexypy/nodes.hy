(defclass Node []
  (defn __init__ [self #* args #** kwargs]
    (setv self.lineno 0)
    (for [[k v] (kwargs.items)]
      (setv (get self.__dict__ k) v)))

  (defn update-dict [self key value]
    (setv (get self.__dict__ key) value))  

  (defn [property] position-info [self]
    {"lineno" self.lineno
     "end_lineno" self.end-lineno
     "col_offset" self.col-offset
     "end_col_offset" self.col-offset}))

(defclass Expression [Node]
  (defn __init__ [self #* tokens #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.list (list tokens))
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

(defclass Starred [Node]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value)
    None)

  (defn __repr__ [self]
    (+ "Star("
       (repr self.value)
       ")"))

  (defn append [self e]
    (.append self.value e))

  (defn update-dict [self key value]
    (setv (get self.__dict__ key) value)
    (.update-dict self.value key value)))

(defclass DoubleStarred [Node]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value)
    None)

  (defn __repr__ [self]
    (+ "DStar("
       (repr self.value)
       ")"))

  (defn append [self e]
    (.append self.value e))

  (defn update-dict [self key value]
    (setv (get self.__dict__ key) value)
    (.update-dict self.value key value)))

(defclass Symbol [Node]
  (defn __init__ [self name #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.name name)
    None)

  (defn __repr__ [self]
    (+ "Sym("
       self.name
       ")"))

  (defn __eq__ [self other]
    (= self.name other)))

(defclass String [Node]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value)
    None)

  (defn __repr__ [self]
    (+ "Str("
       (repr self.value)
       ")")))

(defclass Constant [Node]
  (defn __init__ [self value #** kwargs]
    (.__init__ (super) #** kwargs)
    (setv self.value value)
    None)

  (defn __repr__ [self]
    (+ "Const("
       (repr self.value)
       ")")))

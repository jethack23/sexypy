(require hyrule *)
(import collections [deque])

(import re)

(import functools [reduce])

(import toolz [identity])

(import nodes *)

;;; tokenizer for future which aware of lienno and offset
(defn tokenize [src]
  (setv lines (.split src "\n")
        tokens (deque [])
        patterns [[r"\(" "open-paren"]
                  [r"\)" "close-paren"]
                  [r"\{" "open-brace"]
                  [r"\}" "close-brace"]
                  [r"\[" "open-bracket"]
                  [r"\]" "close-bracket"]
                  [(.join "|" (map (fn [x] (+ r"[rf]?" x))
                                   [r"\'\'\'(?:[^\\']|\\.)*\'\'\'"
                                    r"\"\"\"(?:[^\\\"]|\\.)*\"\"\""
                                    r"\"(?:[^\\\"]|\\.)*\""]))
                   "string"]
                  [r"'(?!\s|$)" "quote"]
                  [r";[^\n]*" "comment"]
                  [(.join "|" (map (fn [x] (+ r"[+-]*" x r"(?=\s|$|\)|\}|\])"))
                                   (reduce (fn [x y] (+ x [(+ y r"e\-?\d+j") (+ y "j")]))
                                           [r"\d+\.\d*"
                                            r"\d*\.\d+"
                                            r"\d+"]
                                           [])))
                   "complex"]
                  #* (zip (map (fn [x] (+ r"[+-]*" x r"(?=\s|$|\)|\}|\])"))
                               (reduce (fn [x y] (+ x [(+ y r"e\-?\d+") y]))
                                       [r"\d+\.\d*"
                                        r"\d*\.\d+"
                                        r"\d+"]
                                       []))
                          (+ (* ["float"] 5)
                             ["int"]))
                  [r"[^\s]+" "symbol"]
                  [r"\n" "new-line"]
                  [r" +" "spaces"]
                  ]
        combined-pattern (.join "|" (lfor [p _] patterns f"({p})"))
        lineno 1
        col-offset 0
        re-applied (reduce (fn [x y] (+ x y))
                           (map (fn [x] (list (filter (fn [y] (get y 0))
                                                      (zip x (get (list (zip #* patterns)) 1)))))
                                (re.findall combined-pattern src))
                           []))
  (for [[tk tktype] re-applied]
    (when (not (in tktype ["new-line" "spaces"]))
      (tokens.append [tk tktype [lineno col-offset]]))
    (setv splitted (tk.split "\n")
          [num-newline col-shift] [(- (len splitted) 1) (len (get splitted -1))])
    (+= lineno num-newline)
    (if (= num-newline 0)
        (+= col-offset col-shift)
        (setv col-offset col-shift)))
  tokens)

(defn parse [src]
  (setv tokens (tokenize src)
        stack []
        rst [])
  (while tokens
    (setv [t tktype [lineno col-offset]] (tokens.popleft))
    (cond (in t ")]}") (do (setv e (stack.pop))
                           (if stack
                               (.append (get stack -1) e)
                               (.append rst e)))
          (= t "(") (stack.append (Paren))
          (= t "[") (stack.append (Bracket))
          (= t "{") (stack.append (Brace))
          True (.append (if stack (get stack -1) rst) (token-parse t tktype))))
  rst)

(defn token-parse [token tktype]
  (cond (and (> (len token) 1) (in (get token 0) "+-")) (unary-op-parse token tktype)
        (= tktype "int") (Constant (int token))
        (= tktype "float") (Constant (float token))
        (= tktype "complex") (Constant (complex token))
        (= tktype "string") (string-parse token)
        True (Symbol token)))

(defn unary-op-parse [token tktype]
  (setv stack []
        idx 0)
  (while (in (get token idx) "+-")
    (stack.append (get token idx))
    (+= idx 1))
  (setv rst (token-parse (get token (slice idx None)) tktype))
  (while stack
    (setv rst (Paren (Symbol (stack.pop)) rst)))
  rst)

(defn string-parse [token]
  (if (token.startswith "f")
      (f-string-parse (get token (slice 2 -1)))
      (String token)))

(defn f-string-parse [token]
  ;; TODO
  )

(require hyrule *)
(import collections [deque])

(import re)

(import functools [reduce])

(import toolz [identity])

(import sexypy.nodes *)

(defn number-condition [pattern]
  (+ r"[+-]*" pattern r"(?=\s|$|\)|\}|\])"))

(setv int-simple r"\d+"
      float-simples [r"\d+\.\d*" r"\d*\.\d+"]
      scientific-simples (list (map (fn [x] (+ x r"e[\-\+]?\d+"))
                                   (+ float-simples [int-simple])))
      number-simple (.join "|" (+ scientific-simples float-simples [int-simple]))
      complex-simple fr"(({number-simple})[+-])?({number-simple})j")

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
                  [(.join "|" (map (fn [x] (+ r"\w*" x))
                                   [r"\'\'\'(?:[^\\']|\\.)*\'\'\'"
                                    r"\"\"\"(?:[^\\\"]|\\.)*\"\"\""
                                    r"\"(?:[^\\\"]|\\.)*\""]))
                   "string"]
                  [r"'(?!\s|$)" "quote"]
                  [r";[^\n]*" "comment"]
                  [(number-condition complex-simple) ["complex" "" "" ""]]
                  [(.join "|" (map number-condition
                                   (+ scientific-simples float-simples))) "float"]
                  [(number-condition int-simple) "int"]
                  [r"[^\s\)\}\]\"]+" "symbol"]
                  [r"\n" "new-line"]
                  [r" +" "spaces"]
                  ]
        combined-pattern (.join "|" (lfor [p _] patterns f"({p})"))
        lineno 1
        col-offset 0
        labels (reduce (fn [x y] (if (isinstance y list)
                                     (+ x y)
                                     (+ x [y])))
                       (get (list (zip #* patterns)) 1)
                       [])
        re-applied (reduce (fn [x y] (+ x y))
                           (map (fn [x] (list (filter (fn [y] (and (get y 0)
                                                                   (get y 1)))
                                                      (zip x labels))))
                                (re.findall combined-pattern src))
                           []))
  (for [[tk tktype] re-applied]
    (setv splitted (tk.split "\n")
          [num-newline col-shift] [(- (len splitted) 1) (len (get splitted -1))]
          end-lineno (+ lineno num-newline)
          end-col-offset (+ col-shift (if (= num-newline 0)
                                          col-offset
                                          0)))
    (when (not (in tktype ["new-line" "spaces" "comment"]))
      (tokens.append [tk tktype
                      {"lineno" lineno
                       "col_offset" col-offset
                       "end_lineno" end-lineno
                       "end_col_offset" end-col-offset}]))
    (setv lineno end-lineno
          col-offset end-col-offset))
  tokens)

(defn position-info-into-list [position-info]
  (list (map (fn [x] (get position-info x))
             ["lineno" "col_offset" "end_lineno" "end_col_offset"])))

(defn parse [src]
  (setv tokens (tokenize src)
        stack []
        rst [])
  (while tokens
    (setv [t tktype position-info]
          (tokens.popleft)
          
          [lineno col-offset end-lineno end-col-offset]
          (position-info-into-list position-info))
    (cond (in t ")]}") (do (setv e (stack.pop)
                                 e.end-lineno end-lineno
                                 e.end-col-offset end-col-offset)
                           (if stack
                               (.append (get stack -1) e)
                               (.append rst e)))
          (= t "(") (stack.append (Paren :lineno lineno :col-offset col-offset))
          (= t "[") (stack.append (Bracket :lineno lineno :col-offset col-offset))
          (= t "{") (stack.append (Brace :lineno lineno :col-offset col-offset))
          True (.append (if stack (get stack -1) rst) (token-parse t tktype position-info))))
  rst)

(defn token-parse [token tktype position-info]
  (cond (and (> (len token) 1) (in (get token 0) "+-")) (unary-op-parse token tktype position-info)
        (= tktype "int") (Constant (int token) #** position-info)
        (= tktype "float") (Constant (float token) #** position-info)
        (= tktype "complex") (Constant (complex token) #** position-info)
        (= tktype "string") (string-parse token position-info)
        True (Symbol token #** position-info)))

(defn unary-op-parse [token tktype position-info]
  (setv stack []
        idx 0
        lineno (get position-info "lineno")
        col-offset (get position-info "col_offset"))
  (while (in (get token idx) "+-")
    (stack.append (Symbol (get token idx) #** {"lineno" lineno
                                               "end_lineno" lineno
                                               "col_offset" (+ col-offset idx)
                                               "end_col_offset" (+ col-offset idx 1)}))
    (+= idx 1))
  (-= (get position-info "col_offset") idx)
  (setv rst (token-parse (get token (slice idx None)) tktype position-info))
  (while stack
    (setv rst (Paren (stack.pop) rst)))
  rst)

(defn string-parse [token position-info]
  (setv [prefix content _] (token.split "\""))
  (if (in "f" prefix)
      (f-string-parse token position-info)
      (String token #** position-info)))

(defn f-string-parse [token]
  ;; TODO
  )

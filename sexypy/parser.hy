(require hyrule *)
(import collections [deque])

(import re)

(import functools [reduce])

(import toolz [identity])

(import sexypy.nodes *
        sexypy.utils [augassignop-dict])

;;; tokenizer for future which aware of lienno and offset
(defn tokenize [src]
  (setv lines (.split src "\n")
        tokens (deque [])
        int-simple r"\d+"
        float-simples [r"\d+\.\d*" r"\d*\.\d+"]
        scientific-simples (list (map (fn [x] (+ x r"e[\-\+]?\d+"))
                                      (+ float-simples [int-simple])))
        number-simple (.join "|" (+ scientific-simples float-simples [int-simple]))
        complex-simple fr"(?:(?:{number-simple})[+-])?(?:{number-simple})j"
        pattern-labels [[r"\^?\*{0,2}[\(\{\[]" "opening"]
                        [r"[\)\}\]]" "closing"]
                        #* (list (zip (map (fn [x] (+ r"\w*" x))
                                           [r"\'\'\'(?:[^\\']|\\.)*\'\'\'"
                                            r"\"\"\"(?:[^\\\"]|\\.)*\"\"\""
                                            r"\"(?:[^\\\"]|\\.)*\""])
                                      ["'''" "\"\"\"" "\""]))
                        [r"(?:'|`|~@|~)(?!\s|$)" "meta-indicator"]
                        [r";[^\n]*" "comment"]
                        [(+ r"[+-]*(?:" (.join "|" [complex-simple number-simple]) r")(?=\s|$|\)|\}|\])")
                         "number"]
                        [r"[^\s\)\}\]\"]+" "symbol"]
                        [r"\n" "new-line"]
                        [r" +" "spaces"]
                        ]
        [patterns labels] (zip #* pattern-labels)
        combined-pattern (.join "|" (map (fn [p] f"({p})") patterns))
        lineno 1
        col-offset 0
        re-applied (reduce (fn [x y] (+ x y))
                           (map (fn [x] (list (filter (fn [y] (get y 0))
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

(setv opening-prefix-dict {"" (fn [value #** kwargs] value)
                           "*" Starred
                           "**" DoubleStarred
                           "^" Annotation})

(setv opening-dict {"(" Paren
                    "{" Brace
                    "[" Bracket})

(setv meta-indicator-dict {"'" Quote
                           "`" QuasiQuote
                           "~" Unquote
                           "~@" UnquoteSplice})

(defn parse [src]
  (setv tokens (tokenize src)
        stack []
        rst [])
  (while tokens
    (setv [t tktype position-info]
          (tokens.popleft)

          [lineno col-offset end-lineno end-col-offset]
          (position-info-into-list position-info))
    (cond (= tktype "opening")
          (stack.append ((get opening-prefix-dict (cut t None -1))
                          :value ((get opening-dict (get t -1))
                                   :lineno lineno
                                   :col-offset (+ col-offset (- (len t) 1)))
                          :lineno lineno
                          :col-offset col-offset))

          (= tktype "meta-indicator")
          (stack.append ((get meta-indicator-dict t)
                          :value None
                          :lineno lineno
                          :col-offset col-offset))

          True
          (do (if (= tktype "closing")
                  (do (setv e (stack.pop))
                      (e.update-dict "end_lineno" end-lineno)
                      (e.update-dict "end_col_offset" end-col-offset))
                  (setv e (token-parse t tktype position-info)))
              (while (and stack (isinstance (get stack -1) MetaIndicator))
                (setv popped (stack.pop)
                      popped.value e)
                (popped.update-dict "end_lineno" end-lineno)
                (popped.update-dict "end_col_offset" end-col-offset)
                (setv e popped))
              (.append (if stack (get stack -1) rst) e))))
  rst)

(setv special-literals #("True" "False" "None" "..."))

(defn token-parse [token tktype position-info]
  (cond (in token augassignop-dict)
        (Symbol token #** position-info)

        (in token special-literals)
        (Constant token #** position-info)

        (and (= tktype "number") (not (in (get token 0) "+-")))
        (Constant token #** position-info)
        
        (in tktype ["'''" "\"\"\"" "\""])
        (string-parse token tktype position-info)

        (< (len token) 2) (Symbol token #** position-info)

        (= (get token 0) "^")
        (annotation-token-parse token tktype position-info)

        (= (get token 0) ":")
        (keyword-token-parse token tktype position-info)

        (= (get token 0) "*")
        (star-token-parse token tktype position-info)

        (in (get token 0) "+-")
        (unary-op-parse token tktype position-info)

        True (Symbol token #** position-info)))

(defn annotation-token-parse [token tktype position-info]
  (setv inner-position {#** position-info})
  (+= (get inner-position "col_offset") 1)
  (Annotation (token-parse (cut token 1 None)
                           tktype
                           inner-position)
              #** position-info))

(defn keyword-token-parse [token tktype position-info]
  (setv inner-position {#** position-info})
  (+= (get inner-position "col_offset") 1)
  (Keyword (token-parse (cut token 1 None)
                        tktype
                        inner-position)
           #** position-info))

(defn star-token-parse [token tktype position-info]
  (setv num-star (if (= (get token 1) "*") 2 1)
        inner-position {#** position-info})
  (+= (get inner-position "col_offset") num-star)
  ((get opening-prefix-dict (* "*" num-star))
    (token-parse (get token (slice num-star None))
                 tktype
                 inner-position)
   #** position-info))

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
  (+= (get position-info "col_offset") idx)
  (setv rst (token-parse (get token (slice idx None)) tktype {#** position-info}))
  (while stack
    (-= (get position-info "col_offset") 1)
    (setv rst (Paren (stack.pop) rst #** position-info)))
  rst)

(defn string-parse [token tktype position-info]
  (setv [prefix #* content _] (token.split tktype))
  (if (in "f" prefix)
      (f-string-parse token #** position-info)
      (String token #** position-info)))

(defn f-string-parse [token #** kwargs]
  ;; TODO
  )

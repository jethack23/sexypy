(import collections [deque])

(import nodes *)

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

(require hyrule *)

(import ast)

(import sxpy.parser *)
(import sxpy.compiler *)
(import sxpy.macro [macroexpand-then-compile])

(defn ast-to-python [st]
  (str (ast.unparse st)))

(when (= __name__ "__main__")
  (defn eval-translate-print [stl]
    (print "\npython translation")
    (print (.join "\n" (list (map ast-to-python stl))))
    (print "\nresult"))
  (while True
    (setv line (input "repl > \n")
          src "")
    (while (!= line "")
      (+= src "\n" line)
      (setv line (input "")))
    (setv parsed (parse src))
    ;; (print (.join "\n" (map str parsed)))
    (setv stl (macroexpand-then-compile parsed))
    ;; (print parsed)
    (eval-translate-print stl)
    (for [st stl]
      (eval (compile (ast.Interactive :body [st]) "" "single")))))

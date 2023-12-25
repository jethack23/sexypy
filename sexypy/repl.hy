(require hyrule *)

(import ast)

(import sexypy.parser *)
(import sexypy.compiler *)

(defn ast-to-python [st]
  (str (ast.unparse st)))

(when (= __name__ "__main__")
  (defn eval-translate-print [stl]
    (print "\npython translation")
    (print (.join "\n" (list (map ast-to-python stl))))
    (print "\nresult"))
  (while True
    (setv parsed (parse (input "calculate > ")))
    (print (.join "\n" (map str parsed)))
    (setv stl (stmt-list-compile parsed))
    (print parsed)
    (eval-translate-print stl)
    (for [st stl]
      (eval (compile (ast.Interactive :body [st]) "" "single")))
    ))

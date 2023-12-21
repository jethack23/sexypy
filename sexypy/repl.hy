(require hyrule *)

(import ast)

(import sexypy.parser *)
(import sexypy.compiler *)

(defn ast-to-python [st]
  (str (ast.unparse st)))

(defn eval-ast [st]
  (eval (compile st "" "single")))

(when (= __name__ "__main__")
  (defn eval-translate-print [stl]
    (print "\npython translation")
    (print (.join "\n" (list (map ast-to-python stl))))
    (print "\nresult")
    (for [st stl]
      (eval-ast st)))
  (while True
    (setv parsed (parse (input "calculate > ")))
    (setv stl (ast-compile parsed))
    (print parsed)
    (eval-translate-print stl)))

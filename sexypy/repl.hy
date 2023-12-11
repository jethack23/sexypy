(require hyrule *)

(import ast)

(import parser *)
(import compiler *)

(when (= __name__ "__main__")
  (defn run-ast [stl]
    (print "\npython translation")
    (print (.join "\n" (list (map str (map ast.unparse stl)))))
    (print "\nresult")
    (for [st stl]
      (eval (compile st "" "single"))))
  (while True
    (setv st (ast-compile (parse (input "calculate > "))))
    (run-ast st)))

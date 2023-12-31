(require hyrule *)

(import ast)
(import subprocess)
(import functools [reduce])

(import sexypy.parser [parse]
        sexypy.compiler [expr-compile]
        sexypy.macro [macroexpand]
        sexypy.repl [ast-to-python])

(defn src-to-python [src]
  (.join "\n" (map ast-to-python (as-> src x
                                      (parse x)
                                      (map macroexpand x)
                                      (filter (fn [x] (not (is x None))) x)
                                      (reduce (fn [rst y] (+ rst (if (isinstance y list)
                                                                     y
                                                                     [y])))
                                              x
                                              [])
                                      (map (fn [x] (if (isinstance x ast.AST)
                                                       x
                                                       (ast.Expr (expr-compile x) #** x.position-info)))
                                           x)))))

(defmain [_ file]
  (with [g (open (.replace file ".hy" ".py") "w")]
    (with [f (open file "r")]
      (setv org (f.read))
      (g.write (src-to-python org))
      (setv lines (.split org "\n"))
      (while (= (get lines -1) "")
        (lines.pop))
      (g.write "\n\n\n# translated from below s-expression\n\n")
      (g.write (.join "\n" (map (fn [x] (+ "# " x))
                                lines)))))
  (subprocess.run ["black" (.replace file ".hy" ".py")])
  (subprocess.run ["python" (.replace file ".hy" ".py")])
  )

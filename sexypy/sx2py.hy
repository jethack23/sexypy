(require hyrule *)

(import subprocess)

(import sexypy.parser [parse]
        sexypy.macro [macroexpand-then-compile]
        sexypy.repl [ast-to-python])

(defn src-to-python [src]
  (.join "\n" (map ast-to-python (-> src
                                     (parse)
                                     (macroexpand-then-compile)))))

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

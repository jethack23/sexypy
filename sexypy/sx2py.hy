(require hyrule *)

(import subprocess)

(import sexypy.parser [parse]
        sexypy.macro [macroexpand-then-compile]
        sexypy.repl [ast-to-python])

(defn src-to-python [src]
  (.join "\n\n\n" (map ast-to-python (-> src
                                         (parse)
                                         (macroexpand-then-compile)))))

(defmain [_ file]
  (with [f (open file "r")]
    (with [g (open (.replace file ".hy" ".py") "w")]
      (g.write (src-to-python (f.read)))))
  (subprocess.run ["black" (.replace file ".hy" ".py")] ))

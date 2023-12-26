(require hyrule *)

(import sexypy.parser [parse]
        sexypy.macro [macroexpand-then-compile]
        sexypy.repl [ast-to-python])

(defn src-to-python [src]
  (.join "\n\n\n" (map ast-to-python (-> src
                                         (parse)
                                         (macroexpand-then-compile)))))

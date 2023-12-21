(require hyrule *)

(import sexypy.parser [parse]
        sexypy.compiler [ast-compile]
        sexypy.repl [ast-to-python])

(defn src-to-python [src]
  (.join "\n" (map ast-to-python (-> src
                                     (parse)
                                     (ast-compile)))))

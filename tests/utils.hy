(require hyrule *)

(import sexypy.parser [parse]
        sexypy.compiler [stmt-list-compile]
        sexypy.repl [ast-to-python])

(defn src-to-python [src]
  (.join "\n\n\n" (map ast-to-python (-> src
                                         (parse)
                                         (stmt-list-compile)))))

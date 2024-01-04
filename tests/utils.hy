(require hyrule *)

(import ast)

(import sexypy.sx2py [parse macroexpand-then-compile src-to-python])

(defn stmt-to-dump [src]
  (-> src
      parse
      macroexpand-then-compile
      (ast.Module :type-ignores [])
      (ast.dump)))

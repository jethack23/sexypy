(require hyrule *)

(import ast)

(defn constant-compile [constant]
  (ast.Constant :value (eval constant.value)
                #** constant.position-info))

(defn string-compile [string]
  (ast.Constant :value (eval string.value)
                #** string.position-info))

;;; Variables in docs
(defn name-compile [symbol ctx]
  (ast.Name :id (symbol.name.replace "-" "_")
            :ctx (ctx)
            #** symbol.position-info))

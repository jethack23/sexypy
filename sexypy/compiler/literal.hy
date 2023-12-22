(require hyrule *)

(import ast)

(defn constant-compile [constant]
  (ast.Constant :value constant.value
                #** constant.position-info))

(defn string-compile [string]
  (setv rst (-> (ast.parse string.value)
                (. body)
                (get 0)
                (. value))
        rst.lineno string.lineno
        rst.col-offset string.col-offset
        rst.end-lineno string.end-lineno
        rst.end-col-offset string.end-col-offset)
  rst)

;;; Variables in docs
(defn name-compile [symbol [ctx ast.Load]]
  (ast.Name :id symbol.name
            :ctx (ctx)
            #** symbol.position-info))

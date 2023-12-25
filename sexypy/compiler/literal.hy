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
  (setv [name #* attrs] (.split (.replace symbol.name "-" "_") ".")
        position-info {#** symbol.position-info}
        (get position-info "end_col_offset") (+ (get position-info "col_offset") (len name))
        rst (ast.Name :id name
                      :ctx (ctx)
                      #** position-info))
  (for [attr attrs]
    (+= (get position-info "end_col_offset") 1 (len attr))
    (setv rst (ast.Attribute :value rst
                             :attr attr
                             :ctx (ctx)
                             #** position-info)))
  rst)

(defmacro import-macro [#* args]
  (do (lfor x args `(import ~(hy.models.Symbol (+ "." x)) *))))

(import-macro
  test-literal
  test-expr
  )

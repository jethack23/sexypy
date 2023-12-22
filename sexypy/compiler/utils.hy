(import sexypy.nodes *)

(defn paren-p [sexp]
  (isinstance sexp Paren))

(defn bracket-p [sexp]
  (isinstance sexp Bracket))

(defn brace-p [sexp]
  (isinstance sexp Brace))

(defn constant-p [sexp]
  (isinstance sexp Constant))

(defn string-p [sexp]
  (isinstance sexp String))

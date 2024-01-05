(import ast)
(import collections [deque])

(import sxpy.nodes *)

(defn paren-p [sexp]
  (isinstance sexp Paren))

(defn bracket-p [sexp]
  (isinstance sexp Bracket))

(defn brace-p [sexp]
  (isinstance sexp Brace))

(defn starred-p [sexp]
  (isinstance sexp Starred))

(defn doublestarred-p [sexp]
  (isinstance sexp DoubleStarred))

(defn constant-p [sexp]
  (isinstance sexp Constant))

(defn string-p [sexp]
  (isinstance sexp String))

(defn keyword-arg-p [sexp]
  (isinstance sexp Keyword))

(defn merge-position-infos [#* position-infos]
  {"lineno" (min (map (fn [x] (get x "lineno")) position-infos))
   "col_offset" (min (map (fn [x] (get x "col_offset")) position-infos))
   "end_lineno" (max (map (fn [x] (get x "end_lineno")) position-infos))
   "end_col_offset" (max (map (fn [x] (get x "end_col_offset")) position-infos))})

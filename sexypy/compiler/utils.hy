(import ast)
(import collections [deque])

(import sexypy.nodes *)

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

(defn def-args-parse [sexp]
  ;; TODO: annotation
  (setv q (deque sexp.list)
        posonlyargs []
        args []
        kwonlyargs []
        kw-defaults []
        defaults [])
  ;; before starred
  (while (and q (not (.startswith (str (get q 0)) "*")))
    (setv arg (q.popleft))
    (cond (= arg "/") (setv posonlyargs args
                            args [])
          (keyword-arg-p arg) (do (args.append (ast.arg :arg arg.name
                                                        #** arg.position-info))
                                  (defaults.append (expr-compile (q.popleft))))
          True (args.append (ast.arg :arg arg.name
                                     #** arg.position-info))))
  ;; starred
  (setv vararg (if (and q (isinstance (get q 0) Starred))
                   (do (setv arg (q.popleft))
                       (ast.arg :arg arg.value.name
                                #** arg.position-info))
                   None))
  (when (and q (= (get q 0) "*"))
    (q.popleft))
  ;; before doublestarred
  (while (and q (and (not (isinstance (get q 0) DoubleStarred))))
    (setv arg (q.popleft))
    (if (keyword-arg-p arg)
        (do (kwonlyargs.append (ast.arg :arg arg.name
                                        #** arg.position-info))
            (kw-defaults.append (expr-compile (q.popleft))))
        (do (kwonlyargs.append (ast.arg :arg arg.name
                                        #** arg.position-info))
            (kw-defaults.append None))))
  ;; doublestarred
  (setv kwarg (if q
                  (do (setv arg (q.popleft))
                      (ast.arg :arg arg.value.name
                               #** arg.position-info))
                  None))
  (ast.arguments :posonlyargs posonlyargs
                 :args args
                 :vararg vararg
                 :kwonlyargs kwonlyargs
                 :kw_defaults kw-defaults
                 :kwarg kwarg
                 :defaults defaults
                 #** sexp.position-info))

(defn merge-position-infos [#* position-infos]
  {"lineno" (min (map (fn [x] (get x "lineno")) position-infos))
   "col_offset" (min (map (fn [x] (get x "col_offset")) position-infos))
   "end_lineno" (max (map (fn [x] (get x "end_lineno")) position-infos))
   "end_col_offset" (max (map (fn [x] (get x "end_col_offset")) position-infos))})

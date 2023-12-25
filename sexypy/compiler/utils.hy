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

(defn keyward-arg-p [sexp]
  (and (isinstance sexp Symbol)
       (sexp.name.startswith ":")))

(defn def-args-parse [sexp]
  ;; TODO: annotation
  (setv q (deque sexp.list)
        posonlyargs []
        args []
        kwonlyargs []
        kw-defaults []
        defaults [])
  ;; before starred
  (while (and q (and (not (isinstance (get q 0) Starred))
                     (!= (get q 0) "*")))
    (setv arg (q.popleft))
    (cond (= arg "/") (setv posonlyargs args
                            args [])
          (keyward-arg-p arg) (do (args.append (ast.arg :arg (get arg.name (slice 1 None))
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
    (if (keyward-arg-p arg)
        (do (kwonlyargs.append (ast.arg :arg (get arg.name (slice 1 None))
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

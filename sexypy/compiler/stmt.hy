(import ast)

(import collections [deque])
(import functools [reduce])

(import sexypy.compiler.expr [expr-compile
                              def-args-parse]
        sexypy.compiler.utils *
        sexypy.utils *)

(defn expr-wrapper [sexp]
  (ast.Expr :value (expr-compile sexp)
            #** sexp.position-info))

(defn do-p [sexp]
  (= (str sexp.op) "do"))

(defn do-compile [sexp]
  (setv [op #* sexps] sexp.list)
  (stmt-list-compile sexps))

(defn assign-p [sexp]
  (= (str sexp.op) "="))

(defn assign-compile [sexp]
  (setv body sexp.operands)
  (if (isinstance (get body 1) Annotation)
      (do (setv [target annotation #* value] body
                value-dict (if value {"value" (expr-compile (get value 0))} {}))
          (print target annotation (repr target))
          (ast.AnnAssign :target (expr-compile target :ctx ast.Store)
                         :annotation (expr-compile annotation)
                         :simple (and (isinstance target Symbol)
                                      (not (in "." (str target))))
                         #** value-dict
                         #** sexp.position-info))
      (do (setv [#* targets value] body)
          (ast.Assign :targets (list (map (fn [x] (expr-compile x :ctx ast.Store)) targets))
                      :value (expr-compile value)
                      #** sexp.position-info)))  )

(defn augassign-p [sexp]
  (in (str sexp.op) augassignop-dict))

(defn augassign-compile [sexp]
  (setv [op target #* args] sexp.list
        op (get augassignop-dict (str op))
        value (reduce (fn [x y] (ast.BinOp x (op) y
                                           #** sexp.position-info))
                      (map expr-compile args)))
  (ast.AugAssign :target (expr-compile target ast.Store)
                 :op (op)
                 :value value
                 #** sexp.position-info))

(defn del-compile [sexp]
  (setv [op #* args] sexp.list)
  (ast.Delete
    :targets (list (map (fn [x] (expr-compile x ast.Del))
                        args))
    #** sexp.position-info))

(defn parse-names [names]
  (setv rst []
        q (deque names))
  (while q
    (setv n (q.popleft))
    (if (= n "as")
        (setv (. (get rst -1) asname) (str (q.popleft)))
        (rst.append (ast.alias :name (str n) #** n.position-info))))
  rst)

(defn import-compile [sexp]
  (setv [_ #* names] sexp.list)
  (ast.Import :names (parse-names names)
              #** sexp.position-info))

(defn importfrom-compile [sexp]
  (setv [_ #* args] sexp.list
        modules (cut args None None 2)
        namess (cut args 1 None 2)
        module-level (map (fn [module]
                            (setv i 0
                                  x module.name)
                            (while (= (get x i) ".")
                              (+= i 1))
                            [(cut x i None) i module.position-info])
                          modules))
  (lfor [[module level module-pos-info] names] (zip module-level namess)
        (ast.ImportFrom :module module
                        :names (parse-names names)
                        :level level
                        #** (merge-position-infos
                              module-pos-info
                              names.position-info))))

(defn if-p [sexp]
  (= (str sexp.op) "if"))

(defn if-stmt-compile [sexp]
  (setv [_ test then #* orelse] sexp.list)
  (ast.If :test (expr-compile test)
          :body (stmt-list-compile [then])
          :orelse (stmt-list-compile [#* orelse])
          #** sexp.position-info))

(defn while-p [sexp]
  (= (str sexp.op) "while"))

(defn while-compile [sexp]
  (setv [_ test #* body] sexp.list
        lastx (get body -1)
        [then orelse] (if (and (isinstance lastx Paren)
                               (= lastx.op "else"))
                          [(cut body None -1) lastx.operands]
                          [body []]))
  (ast.While :test (expr-compile test)
             :body (stmt-list-compile then)
             :orelse (stmt-list-compile orelse)
             #** sexp.position-info))

(defn for-p [sexp]
  (= (str sexp.op) "for"))

(defn for-compile [sexp [async False]]
  (setv [_ target iterable #* body] sexp.list
        lastx (get body -1)
        [then orelse] (if (and (isinstance lastx Paren)
                               (= lastx.op "else"))
                          [(cut body None -1) lastx.operands]
                          [body []]))
  ((if async
       ast.AsyncFor
       ast.For)
    :target (expr-compile target ast.Store)
    :iter (expr-compile iterable)
    :body (stmt-list-compile then)
    :orelse (stmt-list-compile orelse)
   #** sexp.position-info))

(defn deco-p [sexp]
  (= (str sexp.op) "deco"))

(defn raise-compile [sexp]
  (setv body sexp.operands)
  (assert (or (= (len body) 1)
              (and (= (len body) 3)
                   (= (get body 1) "from"))))
  (setv kwargs {"exc" (expr-compile (get body 0))})
  (when (> (len body) 1)
    (setv (get kwargs "cause") (expr-compile (get body -1))))
  (ast.Raise #** kwargs
             #** sexp.position-info))
 
(defn assert-compile [sexp]
  (setv kwargs {"test" (expr-compile (get sexp 1))})
  (when (> (len sexp 2))
    (setv (get kwargs "msg") (expr-compile (get sexp 2))))
  (ast.Assert #** kwargs
              #** sexp.position-info))

(defn parse-exception-bracket [bracket]
  (setv lst bracket.list)
  (setv name (if (and (> (len lst) 2)
                      (= (get lst -2) "as"))
                 (str (get [(lst.pop) (lst.pop)] 1))
                 None))
  (setv type (if (> (len lst) 1)
                 (ast.Tuple :elts (list (map expr-compile lst))
                            :ctx (ast.Load)
                            #** bracket.position-info)
                 (expr-compile (get lst 0))))
  [type name])

(defn parse-except [handler]
  (setv body handler.operands)
  (setv [type name] (if (isinstance (get body 0) Bracket)
                        (do (setv body (deque handler.operands))
                            (parse-exception-bracket (body.popleft)))
                        [None None]))
  (setv kwargs {"body" (stmt-list-compile body)})
  (when type
    (setv (get kwargs "type") type))
  (when name
    (setv (get kwargs "name") name))
  (ast.ExceptHandler #** kwargs
                     #** handler.position-info))

(defn try-compile [sexp]
  (setv body sexp.operands)
  ;; finally
  (setv finalbody (if (and (isinstance (get body -1) Paren)
                           (= (. (get body -1) op) "finally"))
                      (. (body.pop) operands)
                      []))
  ;; else
  (setv orelse (if (and (isinstance (get body -1) Paren)
                        (= (. (get body -1) op) "else"))
                   (. (body.pop) operands)
                   []))
  ;; excepts
  (setv handlers (deque))
  (while (and (isinstance (get body -1) Paren)
              (= (. (get body -1) op) "except"))
    (handlers.appendleft (body.pop)))
  (setv handlers (list (map parse-except handlers)))

  ;; except*s
  (setv starhandlers (deque))
  (while (and (isinstance (get body -1) Paren)
              (= (. (get body -1) op) "except*"))
    (starhandlers.appendleft (body.pop)))
  (setv starhandlers (list (map parse-except starhandlers)))

  (assert (or (not starhandlers) (not handlers)))

  ((if (not starhandlers)
       ast.Try
       ast.TryStar)
    :body (stmt-list-compile body)
    :handlers (or handlers starhandlers)
    :orelse (stmt-list-compile orelse)
    :finalbody (stmt-list-compile finalbody)
   #** sexp.position-info))

(defn with-items-parse [sexp]
  (setv rst []
        q (deque sexp.list))
  (while q
    (setv elt (q.popleft))
    (if (= (str elt) "as")
        (setv (. (get rst -1) optional-vars) (expr-compile (q.popleft) :ctx ast.Store))
        (rst.append (ast.withitem :context-expr (expr-compile elt)))))
  rst)

(defn with-compile [sexp [async False]]
  (setv [bracket-sexp #* body] sexp.operands
        items (with-items-parse bracket-sexp))
  ((if async
       ast.AsyncWith
       ast.With)
    :items items
    :body (stmt-list-compile body)
    #** sexp.position-info))

(defn deco-compile [sexp decorator-list]
  (setv [op decorator def-statement] sexp.list
        new-deco-list (if (isinstance decorator Bracket)
                          decorator.list
                          [decorator]))
  (stmt-compile def-statement (+ (if decorator-list decorator-list []) new-deco-list)))

(defn functiondef-p [sexp]
  (= (str sexp.op) "def"))

(defn functiondef-compile [sexp decorator-list [async False]]
  (setv [op fnname args #* body] sexp.list)
  (if (and body (isinstance (get body 0) Annotation))
      (setv [ann #* body] body)
      (setv ann None))
  ((if async
       ast.AsyncFunctionDef
       ast.FunctionDef)
    :name fnname.name
    :args (def-args-parse args)
    :body (stmt-list-compile body)
    :decorator-list (if decorator-list
                        (list (map expr-compile decorator-list))
                        [])
    :returns (if ann (expr-compile ann.value) None)
    #** sexp.position-info))

(defn return-p [sexp]
  (= (str sexp.op) "return"))

(defn return-compile [sexp]
  (setv [op value] sexp.list)
  (ast.Return :value (expr-compile value)
              #** sexp.position-info))

(defn global-compile [sexp]
  (setv [_ #* args] sexp.list)
  (ast.Global :names (list (map (fn [x] x.name) args))
              #** sexp.position-info))

(defn nonlocal-compile [sexp]
  (setv [_ #* args] sexp.list)
  (ast.Nonlocal :names (list (map (fn [x] x.name) args))
                #** sexp.position-info))

(defn classdef-p [sexp]
  (= (str sexp.op) "class"))

(defn classdef-args-parse [args]
  (setv q (deque args)
        bases []
        keywords [])
  (while q
    (setv arg (q.popleft))
    (if (keyword-arg-p arg)
        (keywords.append (ast.keyword :arg arg.name
                                      :value (expr-compile (q.popleft))
                                      #** arg.position-info))
        (bases.append (expr-compile arg))))
  [bases keywords])

(defn classdef-compile [sexp decorator-list]
  (setv [_ clsname args #*body] sexp.list
        [bases keywords] (classdef-args-parse args))
  (ast.ClassDef
    :name clsname.name
    :bases bases
    :keywords keywords
    :body (stmt-list-compile body)
    :decorator-list (if decorator-list
                        (list (map expr-compile decorator-list))
                        [])
    #** sexp.position-info))

(defn stmt-compile [sexp [decorator-list None]]
  (cond (not (paren-p sexp)) (expr-wrapper sexp)
        (do-p sexp) (do-compile sexp)
        (assign-p sexp) (assign-compile sexp)
        (augassign-p sexp) (augassign-compile sexp)
        (= (str sexp.op) "del") (del-compile sexp)
        (= (str sexp.op) "pass") (ast.Pass #** sexp.position-info)
        (= (str sexp.op) "import") (import-compile sexp)
        (= (str sexp.op) "from") (importfrom-compile sexp)
        (if-p sexp) (if-stmt-compile sexp)
        (while-p sexp) (while-compile sexp)
        (for-p sexp) (for-compile sexp)
        (= (str sexp.op) "break") (ast.Break #** sexp.position-info)
        (= (str sexp.op) "continue") (ast.Continue #** sexp.position-info)
        (= (str sexp.op) "raise") (raise-compile sexp)
        (= (str sexp.op) "assert") (assert-compile sexp)
        (= (str sexp.op) "try") (try-compile sexp)
        (= (str sexp.op) "with") (with-compile sexp)
        (deco-p sexp) (deco-compile sexp decorator-list)
        (functiondef-p sexp) (functiondef-compile sexp decorator-list)
        (return-p sexp) (return-compile sexp)
        (= (str sexp.op) "global") (global-compile sexp)
        (= (str sexp.op) "nonlocal") (nonlocal-compile sexp)
        (classdef-p sexp) (classdef-compile sexp decorator-list)
        (= (str sexp.op) "async-def") (functiondef-compile sexp decorator-list :async True)
        (= (str sexp.op) "async-for") (with-compile sexp :async True)
        (= (str sexp.op) "async-with") (with-compile sexp :async True)
        ;; TODO: statements, imports, control flows, Pattern Matching, function and class definitions, async and await
        True (expr-wrapper sexp)))

(defn stmt-list-compile [sexp-list]
  (reduce (fn [x y] (+ x (if (isinstance y list)
                             y
                             [y])))
          (map stmt-compile sexp-list)
          []))

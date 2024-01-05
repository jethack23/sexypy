(require hyrule *)

(import ast)
(import argparse)
(import os)
(import os.path :as osp)
(import subprocess)

(import black)

(import sxpy.parser [parse]
        sxpy.macro [macroexpand-then-compile])

(defn ast-to-python [st]
  (str (ast.unparse st)))

(defn src-to-python [src]
  (.join "\n" (map ast-to-python (-> src
                                     (parse)
                                     (macroexpand-then-compile)))))

(setv argparser (argparse.ArgumentParser))
(argparser.add-argument "filename"
                        :nargs "?"
                        :default "")
(argparser.add-argument "-t" "--translate"
                        :dest "translate"
                        :action "store_const"
                        :const True
                        :default False)

(defn transcompile []
  (setv args (argparser.parse-args)
        file (osp.join (os.getcwd) args.filename))
  (with [f (open file "r")]
    (setv org (f.read)
          blacked (.rstrip (black.format-str
                             (src-to-python org)
                             :mode (black.FileMode))
                           "\n")))
  (print blacked))

(defn run-sy [file]
  (with [f (open file "r")]
    (exec (compile (ast.Module :body (macroexpand-then-compile
                                       (parse (f.read)))
                               :type-ignores [])
                   (osp.basename file)
                   "exec"))))

(defn repl [translate]
  (while True
    (setv line (input "repl > \n")
          src "")
    (while (!= line "")
      (+= src "\n" line)
      (setv line (input "")))
    (setv parsed (parse src))
    ;; (print parsed)
    ;; (print (.join "\n" (map str parsed)))
    (setv stl (macroexpand-then-compile parsed))
    (when translate
      (print "\npython translation")
      (print (.join "\n" (list (map ast-to-python stl)))))
    (print "\nresult")
    (for [st stl]
      (eval (compile (ast.Interactive :body [st]) "" "single")))))

(defn run []
  (setv args (argparser.parse-args))
  (if args.filename
      (run-sy args.filename)
      (repl args.translate)))

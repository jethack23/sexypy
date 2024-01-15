(require hyrule *)

(import ast)
(import argparse)
(import io)
(import os)
(import os.path :as osp)
(import runpy)
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

(defn _is-sy-file [filename]
  (and (osp.isfile filename)
       (in (get (osp.splitext filename) 1) [".sy"])))

;;; runpy injection
(defn inject-runpy []
  (setv _org-get-code-from-file runpy._get_code_from_file)
  
  (defn _get-sy-code-from-file [run-name fname]
    (import pkgutil [read-code])
    (setv decoded-path (osp.abspath (os.fsdecode fname)))

    (with [f (io.open-code decoded-path)]
      (setv code (read-code f)))

    (when (is code None)
      (setv code (if (_is-sy-file fname)
                     (with [f (open decoded-path "r")]
                       (-> (f.read)
                           (parse)
                           (macroexpand-then-compile)
                           (ast.Module :type-ignores [])
                           (compile fname "exec")))
                     (get (_org-get-code-from-file run-name fname) 0))))
    [code fname])
  
  (setv runpy._get_code_from_file _get-sy-code-from-file))

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
      (print "python translation")
      (print (.join "\n" (list (map ast-to-python stl))))
      (print ""))
    (print "result")
    (for [st stl]
      (eval (compile (ast.Interactive :body [st]) "" "single")
            (globals)))
    (print "\n")))

(defn run []
  (setv args (argparser.parse-args))
  (if args.filename
      (runpy.run-path args.filename :run-name "__main__")
      (repl args.translate))
  None)

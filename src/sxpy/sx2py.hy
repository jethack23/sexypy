(require hyrule *)

(import argparse)
(import os)
(import os.path :as osp)
(import subprocess)

(import sxpy.parser [parse]
        sxpy.macro [macroexpand-then-compile]
        sxpy.repl [ast-to-python])

(defn src-to-python [src]
  (.join "\n" (map ast-to-python (-> src
                                     (parse)
                                     (macroexpand-then-compile)))))

(setv argparser (argparse.ArgumentParser))
(argparser.add-argument "filename")

(defn transcompile []
  (setv args (argparser.parse-args)
        file (osp.join (os.getcwd) args.filename)
        newfile (+ (get (osp.splitext file) 0) ".py"))
  (with [g (open newfile "w")]
    (with [f (open file "r")]
      (setv org (f.read))
      (g.write (src-to-python org))
      (setv lines (.split org "\n"))
      (while (= (get lines -1) "")
        (lines.pop))
      (g.write "\n\n\n# translated from below s-expression\n\n")
      (g.write (.join "\n" (map (fn [x] (+ "# " x))
                                lines)))))
  (subprocess.run ["black" newfile])
  (subprocess.run ["python" newfile]))

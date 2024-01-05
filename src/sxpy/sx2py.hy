(require hyrule *)

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

(defmain [_ file]
  (setv file (osp.join (os.getcwd) file)
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

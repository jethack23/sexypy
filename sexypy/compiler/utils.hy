(import sexypy.nodes *)

(defn paren-p [expr]
  (isinstance expr Paren))

(defn bracket-p [expr]
  (isinstance expr Bracket))

(defn brace-p [expr]
  (isinstance expr Brace))

(defn constant-p [expr]
  (isinstance expr Constant))

(defn string-p [expr]
  (isinstance expr String))

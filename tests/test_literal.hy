(require hyrule *)

(import unittest)

(import sexypy.parser [parse]
        sexypy.compiler [ast-compile]
        sexypy.repl [ast-to-python])

(defn src-to-python [src]
  (.join "\n" (map ast-to-python (-> src
                                     (parse)
                                     (ast-compile)))))

(defmacro self-retrieval-assert [src]
  `(equal-test ~src ~src))

(defmacro equal-test [a b]
  `(self.assertEqual (src-to-python ~a) ~b))

(defclass TestNumberMethods [unittest.TestCase]
  
  (defn test-integer [self]
    (self-retrieval-assert "1")
    (self-retrieval-assert "21234"))

  (defn test-float [self]
    (self-retrieval-assert "12.34")
    (equal-test "12." "12.0")
    (equal-test ".34" "0.34"))

  (defn test-scientific-notation [self]
    (equal-test "1e3" "1000.0")
    (equal-test "12.34e3" "12340.0"))

  (defn test-complex [self]
    (equal-test "3j" "3j")
    (equal-test "1+2j" "(1+2j)")
    (equal-test "1e3-.34j" "(1000-0.34j)")))

(defclass TestStringMethods [unittest.TestCase]
  (defn test-string [self]
    (equal-test "\"asdfasdf\"" "'asdfasdf'"))

  (defn test-raw-string [self]
    (equal-test "r\"\\n\"" "'\\\\n'")
    (equal-test "\"\\n\"" "'\\n'")))

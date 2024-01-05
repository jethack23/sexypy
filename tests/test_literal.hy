(require hyrule *)

(import ast)
(import unittest)

(import sexypy.sx2py [src-to-python])
(import .utils [stmt-to-dump])

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
    (equal-test "\"\\n\"" "'\\n'"))

  (defn test-f-string [self]
    (self.assertEqual (stmt-to-dump "f\"sin({a}) is {(sin a):.3}\"")
                      (ast.dump (ast.parse "f\"sin({a}) is {sin(a):.3}\"")))))

(defclass TestListMethods [unittest.TestCase]

  (defn test-list [self]
    (self.assertEqual (src-to-python "[1 2]") "[1, 2]"))

  (defn test-star [self]
    (self.assertEqual (src-to-python "[*[1 2]]")
                      "[*[1, 2]]")
    (self.assertEqual (src-to-python "[1 2 *[3 4]]")
                      "[1, 2, *[3, 4]]")))

(defclass TestTupleMethods [unittest.TestCase]

  (defn test-tuple [self]
    (self.assertEqual (src-to-python "(, 1 2)") "(1, 2)"))

  (defn test-star [self]
    (self.assertEqual (src-to-python "(, *[1 2])")
                      "(*[1, 2],)")
    (self.assertEqual (src-to-python "(, 1 2 *[3 4])")
                      "(1, 2, *[3, 4])")))


(defclass TestDictMethods [unittest.TestCase]

  (defn test-dict [self]
    (self.assertEqual (src-to-python "{1 2}") "{1: 2}"))

  (defn test-double-star [self]
    (self.assertEqual (src-to-python "{1 2 **a **{3 4}}")
                      "{1: 2, **a, **{3: 4}}")))


(defclass TestSetMethods [unittest.TestCase]

  (defn test-set [self]
    (self.assertEqual (src-to-python "{, 1 2}")
                      "{1, 2}"))

  (defn test-star [self]
    (self.assertEqual (src-to-python "{, *[1 2 3] 2 3 4}")
                      "{*[1, 2, 3], 2, 3, 4}")))

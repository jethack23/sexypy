(require hyrule *)

(import unittest)

(import .utils [parse ast-compile src-to-python])

(defclass TestUnaryOpMethods [unittest.TestCase]

  (defn test-unaryop [self]
    (self.assertEqual (src-to-python "+2") "+2")))

(defclass TestBinOpMethods [unittest.TestCase]

  (defn test-binop [self]
    (self.assertEqual (src-to-python "(+ 2 3)") "2 + 3")))

(defclass TestBoolOpMethods [unittest.TestCase]

  (defn test-boolop [self]
    (self.assertEqual (src-to-python "(and 1 2)") "1 and 2")))

(defclass TestCallMethods [unittest.TestCase]
  
  (defn test-call [self]
    ;; dummy test case
    (self.assertEqual (parse "((a b c) d e)") "asdf")))

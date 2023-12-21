(require hyrule *)

(import unittest)

(import .utils [parse ast-compile src-to-python])

(defclass TestCallMethods [unittest.TestCase]
  
  (defn test-call [self]
    ;; dummy test case
    (self.assertEqual (parse "((a b c) d e)") "asdf")))

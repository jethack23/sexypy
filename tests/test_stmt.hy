(import ast
        unittest)

(import .utils [stmt-to-dump])


(defclass TestMatchMethods [unittest.TestCase]

  (defn test-match-value [self]
    (self.assertEqual (stmt-to-dump "
(match x
  (case \"Relevant\" ...))")
                      (ast.dump (ast.parse "
match x:
    case \"Relevant\":
        ..."))))

  (defn test-match-singleton [self]
    (self.assertEqual (stmt-to-dump "
(match x 
  (case None
     ...))")
                      (ast.dump (ast.parse "
match x:
    case None:
        ..."))))

  (defn test-match-sequence [self]
    (self.assertEqual (stmt-to-dump "
(match x 
  (case [1 2]
     ...))")
                      (ast.dump (ast.parse "
match x:
    case [1, 2]:
        ..."))))

  (defn test-match-star [self]
    (self.assertEqual (stmt-to-dump "
(match x
  (case [1 2 *rest]
     ...)
  (case [*_]
    ...))")
                      (ast.dump (ast.parse "
match x:
    case [1, 2, *rest]:
        ...
    case [*_]:
        ..."))))

  (defn test-match-mapping [self]
    (self.assertEqual (stmt-to-dump "
(match x
  (case {1 _ 2 _}
    ...)
  (case {**rest}
    ...))")
                      (ast.dump (ast.parse "
match x:
    case {1: _, 2: _}:
        ...
    case {**rest}:
        ..."))))

  (defn test-match-class [self]
    (self.assertEqual (stmt-to-dump "
(match x
  (case (Point2D 0 0)
    ...)
  (case (Point3D :x 0 :y 0 :z 0)
    ...))")
                      (ast.dump (ast.parse "
match x:
    case Point2D(0, 0):
        ...
    case Point3D(x=0, y=0, z=0):
        ..."))))

  (defn test-match-as [self]
    (self.assertEqual (stmt-to-dump "
(match x
  (case [x] as y
    ...)
  (case _
    ...))")
                      (ast.dump (ast.parse "
match x:
    case [x] as y:
        ...
    case _:
        ..."))))

  (defn test-match-or [self]
    (self.assertEqual (stmt-to-dump "
(match x
  (case (| [x] y)
    ...))")
                      (ast.dump (ast.parse "
match x:
    case [x] | (y):
        ...")))))


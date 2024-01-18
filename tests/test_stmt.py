import ast
import unittest

from .utils import stmt_to_dump


class TestMatchMethods(unittest.TestCase):
    def test_match_value(self):
        return self.assertEqual(
            stmt_to_dump('\n(match x\n  (case "Relevant" ...))'),
            ast.dump(ast.parse('\nmatch x:\n    case "Relevant":\n        ...')),
        )

    def test_match_singleton(self):
        return self.assertEqual(
            stmt_to_dump("\n(match x \n  (case None\n     ...))"),
            ast.dump(ast.parse("\nmatch x:\n    case None:\n        ...")),
        )

    def test_match_sequence(self):
        return self.assertEqual(
            stmt_to_dump("\n(match x \n  (case [1 2]\n     ...))"),
            ast.dump(ast.parse("\nmatch x:\n    case [1, 2]:\n        ...")),
        )

    def test_match_star(self):
        return self.assertEqual(
            stmt_to_dump(
                "\n(match x\n  (case [1 2 *rest]\n     ...)\n  (case [*_]\n    ...))"
            ),
            ast.dump(
                ast.parse(
                    "\nmatch x:\n    case [1, 2, *rest]:\n        ...\n    case [*_]:\n        ..."
                )
            ),
        )

    def test_match_mapping(self):
        return self.assertEqual(
            stmt_to_dump(
                "\n(match x\n  (case {1 _ 2 _}\n    ...)\n  (case {**rest}\n    ...))"
            ),
            ast.dump(
                ast.parse(
                    "\nmatch x:\n    case {1: _, 2: _}:\n        ...\n    case {**rest}:\n        ..."
                )
            ),
        )

    def test_match_class(self):
        return self.assertEqual(
            stmt_to_dump(
                "\n(match x\n  (case (Point2D 0 0)\n    ...)\n  (case (Point3D :x 0 :y 0 :z 0)\n    ...))"
            ),
            ast.dump(
                ast.parse(
                    "\nmatch x:\n    case Point2D(0, 0):\n        ...\n    case Point3D(x=0, y=0, z=0):\n        ..."
                )
            ),
        )

    def test_match_as(self):
        return self.assertEqual(
            stmt_to_dump(
                "\n(match x\n  (case [x] as y\n    ...)\n  (case _\n    ...))"
            ),
            ast.dump(
                ast.parse(
                    "\nmatch x:\n    case [x] as y:\n        ...\n    case _:\n        ..."
                )
            ),
        )

    def test_match_or(self):
        return self.assertEqual(
            stmt_to_dump("\n(match x\n  (case (| [x] y)\n    ...))"),
            ast.dump(ast.parse("\nmatch x:\n    case [x] | (y):\n        ...")),
        )

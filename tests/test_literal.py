import ast
import unittest
from sxpy.tools import src_to_python
from .utils import stmt_to_dump


class TestNumberMethods(unittest.TestCase):
    def test_integer(self):
        self.assertEqual(src_to_python("1"), "1")
        return self.assertEqual(src_to_python("21234"), "21234")

    def test_float(self):
        self.assertEqual(src_to_python("12.34"), "12.34")
        self.assertEqual(src_to_python("12."), "12.0")
        return self.assertEqual(src_to_python(".34"), "0.34")

    def test_scientific_notation(self):
        self.assertEqual(src_to_python("1e3"), "1000.0")
        return self.assertEqual(src_to_python("12.34e3"), "12340.0")

    def test_complex(self):
        self.assertEqual(src_to_python("3j"), "3j")
        self.assertEqual(src_to_python("1+2j"), "(1+2j)")
        return self.assertEqual(src_to_python("1e3-.34j"), "(1000-0.34j)")


class TestStringMethods(unittest.TestCase):
    def test_string(self):
        return self.assertEqual(src_to_python('"asdfasdf"'), "'asdfasdf'")

    def test_raw_string(self):
        self.assertEqual(src_to_python('r"\\n"'), "'\\\\n'")
        return self.assertEqual(src_to_python('"\\n"'), "'\\n'")

    def test_f_string(self):
        return self.assertEqual(
            stmt_to_dump('f"sin({a}) is {(sin a):.3}"'),
            ast.dump(ast.parse('f"sin({a}) is {sin(a):.3}"')),
        )


class TestListMethods(unittest.TestCase):
    def test_list(self):
        return self.assertEqual(src_to_python("[1 2]"), "[1, 2]")

    def test_star(self):
        self.assertEqual(src_to_python("[*[1 2]]"), "[*[1, 2]]")
        return self.assertEqual(src_to_python("[1 2 *[3 4]]"), "[1, 2, *[3, 4]]")


class TestTupleMethods(unittest.TestCase):
    def test_tuple(self):
        return self.assertEqual(src_to_python("(, 1 2)"), "(1, 2)")

    def test_star(self):
        self.assertEqual(src_to_python("(, *[1 2])"), "(*[1, 2],)")
        return self.assertEqual(src_to_python("(, 1 2 *[3 4])"), "(1, 2, *[3, 4])")


class TestDictMethods(unittest.TestCase):
    def test_dict(self):
        return self.assertEqual(src_to_python("{1 2}"), "{1: 2}")

    def test_double_star(self):
        return self.assertEqual(
            src_to_python("{1 2 **a **{3 4}}"), "{1: 2, **a, **{3: 4}}"
        )


class TestSetMethods(unittest.TestCase):
    def test_set(self):
        return self.assertEqual(src_to_python("{, 1 2}"), "{1, 2}")

    def test_star(self):
        return self.assertEqual(
            src_to_python("{, *[1 2 3] 2 3 4}"), "{*[1, 2, 3], 2, 3, 4}"
        )

import unittest
from sxpy.tools import parse, src_to_python


class TestUnaryOpMethods(unittest.TestCase):
    def test_unaryop(self):
        return self.assertEqual(src_to_python("+2"), "+2")


class TestBinOpMethods(unittest.TestCase):
    def test_binop(self):
        return self.assertEqual(src_to_python("(+ 2 3)"), "2 + 3")


class TestBoolOpMethods(unittest.TestCase):
    def test_boolop(self):
        return self.assertEqual(src_to_python("(and 1 2)"), "1 and 2")


class TestCompareMethods(unittest.TestCase):
    def test_eq(self):
        return self.assertEqual(src_to_python("(== 1 2 3)"), "1 == 2 == 3")

    def test_noteq(self):
        return self.assertEqual(src_to_python("(!= 1 2 3)"), "1 != 2 != 3")

    def test_lt(self):
        return self.assertEqual(src_to_python("(< 1 2 3)"), "1 < 2 < 3")

    def test_lte(self):
        return self.assertEqual(src_to_python("(<= 1 2 3)"), "1 <= 2 <= 3")

    def test_gt(self):
        return self.assertEqual(src_to_python("(> 1 2 3)"), "1 > 2 > 3")


class TestCallMethods(unittest.TestCase):
    def test_call(self):
        return self.assertEqual(parse("((a b c) d e)"), "asdf")

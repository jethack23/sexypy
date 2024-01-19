import ast

from sxpy.tools import macroexpand_then_compile, parse, src_to_python


def stmt_to_dump(src):
    return ast.dump(ast.Module(macroexpand_then_compile(parse(src)), type_ignores=[]))

import ast
import sys
import importlib
import importlib.abc
import os

from sxpy.parser import parse
from sxpy.macro import macroexpand_then_compile


class SyFinder(importlib.abc.MetaPathFinder):
    def find_spec(self, fullname, path=None, target=None):
        if path is None:
            path = []

        path_extension = [os.getcwd()] + sys.path
        path += path_extension

        for entry in path:
            filename = entry + "/" + fullname.replace(".", "/") + ".sy"
            try:
                with open(filename, "r"):
                    return importlib.util.spec_from_file_location(
                        fullname, filename, loader=SyLoader()
                    )
            except FileNotFoundError:
                pass

        return None


class SyLoader(importlib.abc.Loader):
    def exec_module(self, module):
        with open(module.__file__, "rb") as file:
            source = file.read().decode("utf-8")

        parsed = parse(source)
        ast_module = ast.Module(macroexpand_then_compile(parsed), type_ignores=[])
        code_obj = compile(ast_module, module.__file__, "exec")
        exec(code_obj, module.__dict__)

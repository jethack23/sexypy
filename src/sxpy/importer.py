import ast
import sys
import importlib
import importlib.abc
import io
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
        code = self.get_code_from_file(module.__file__)
        exec(code, module.__dict__)

    def get_code_from_file(self, filename):
        from pkgutil import read_code

        decoded_path = os.path.abspath(os.fsdecode(filename))
        with io.open_code(decoded_path) as f:
            code = read_code(f)

        if code is None:
            with open(filename, "rb") as file:
                source = file.read().decode("utf-8")

            parsed = parse(source)
            ast_module = ast.Module(macroexpand_then_compile(parsed), type_ignores=[])
            code = compile(ast_module, filename, "exec")
        return code

    def get_code(self, fullname):
        path = []
        path_extension = [os.getcwd()] + sys.path
        path += path_extension
        for entry in path:
            filename = entry + "/" + fullname.replace(".", "/") + ".sy"
            try:
                return self.get_code_from_file(filename)
            except FileNotFoundError:
                pass

        return None

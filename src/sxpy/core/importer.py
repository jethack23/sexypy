import ast
import importlib
import importlib.abc
import io
import os
import sys

from sxpy.core.macro import macroexpand_then_compile
from sxpy.core.parser import parse


class SyFinder(importlib.abc.MetaPathFinder):
    def find_spec(self, fullname, path=None, target=None):
        if path is None:
            path = []
        elif not isinstance(path, list):
            path = [path]
        path_extension = [os.getcwd()] + sys.path
        path += path_extension

        for entry in path:
            for ext in [".sy", ".py", "/__init__.sy", "/__init__.py"]:
                filename = entry + "/" + fullname.replace(".", "/") + ext
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
        if os.path.splitext(module.__file__)[0].endswith("__init__"):
            module.__path__ = os.path.dirname(module.__file__)
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
            if filename.endswith(".sy"):
                parsed = parse(source)
                source = ast.Module(macroexpand_then_compile(parsed), type_ignores=[])
            code = compile(source, filename, "exec")
        return code

    def get_code(self, fullname):
        path = []
        path_extension = [os.getcwd()] + sys.path
        path += path_extension
        for entry in path:
            for ext in [".sy", ".py"]:  # sy first
                filename = entry + "/" + fullname.replace(".", "/") + ext
                try:
                    return self.get_code_from_file(filename)
                except FileNotFoundError:
                    pass

        return None

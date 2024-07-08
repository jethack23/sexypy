import ast
from importlib import machinery
import os.path as osp
import sys

from sxpy.core.macro import macroexpand_then_compile
from sxpy.core.parser import parse


def _is_sy_file(filename):
    return osp.isfile(filename) and osp.splitext(filename)[1] == ".sy"


# # importlib.machinery.SourceFileLoader.source_to_code injection
machinery.SOURCE_SUFFIXES.insert(0, ".sy")
_org_source_to_code = machinery.SourceFileLoader.source_to_code


def _sy_source_to_code(self, data, path, _optimize=-1):
    if _is_sy_file(path):
        source = data.decode("utf-8")
        parsed = parse(source)
        data = ast.Module(macroexpand_then_compile(parsed), type_ignores=[])

    return _org_source_to_code(self, data, path, _optimize=_optimize)


machinery.SourceFileLoader.source_to_code = _sy_source_to_code

sys.path_importer_cache.clear()

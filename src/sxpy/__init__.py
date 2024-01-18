import sys

from sxpy.core.importer import SyFinder

sys.meta_path.append(SyFinder())

from sxpy.tools import inject_runpy, run, transcompile

inject_runpy()

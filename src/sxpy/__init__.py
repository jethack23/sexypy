import sys
from sxpy.importer import SyFinder

sys.meta_path.append(SyFinder())

from sxpy.tools import transcompile, run, inject_runpy

inject_runpy()

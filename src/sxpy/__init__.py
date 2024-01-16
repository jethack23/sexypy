import hy

import sys
from sxpy.importer import SyFinder

sys.meta_path.append(SyFinder())

from .init import *

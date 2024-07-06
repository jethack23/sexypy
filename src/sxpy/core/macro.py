import ast
import importlib
from typing import Callable, Dict

from sxpy.core.compiler import def_args_parse, stmt_list_compile
from sxpy.core.nodes import *

__macro_namespace: Dict[str, Callable[[Node], ast.AST]] = {}


def define_macro(sexp, scope):
    [op, macroname, args, *body] = sexp.list
    new_name = "___macro___" + str(macroname)
    def_exp = ast.FunctionDef(
        name=new_name,
        args=def_args_parse(args),
        body=macroexpand_then_compile(body, scope),
        decorator_list=[],
        returns=None,
        **sexp.position_info,
    )
    eval(
        compile(ast.Interactive(body=[def_exp]), "macro-defining", "single"),
        scope,
    )
    scope["__macro_namespace"][str(macroname)] = scope[new_name]


def require_macro(sexp, scope):
    [op, module_name, *optional] = sexp.list
    imported_macros = importlib.import_module(
        str(module_name).replace("-", "_")
    ).__macro_namespace
    if optional:
        [macro_names] = optional
        if str(macro_names) == "*":
            scope["__macro_namespace"].update(imported_macros)
        else:
            for mac_name in map(str, macro_names.list):
                scope["__macro_namespace"][mac_name] = imported_macros[mac_name]
    else:
        for k, v in imported_macros.items():
            scope["__macro_namespace"][str(module_name) + "." + k] = v


def macroexpand(sexp, scope):
    if isinstance(sexp, Wrapper) or isinstance(sexp, MetaIndicator):
        sexp.value = macroexpand(sexp.value, scope)
    elif isinstance(sexp, Expression) and len(sexp) > 0:
        [op, *operands] = sexp.list
        if str(op) == "defmacro":
            sexp = define_macro(sexp, scope)
        elif str(op) == "require":
            sexp = require_macro(sexp, scope)
        elif str(op) in scope["__macro_namespace"]:
            sexp = macroexpand(scope["__macro_namespace"][str(op)](*operands), scope)
        else:
            sexp.list = list(
                filter(
                    lambda x: not x is None,
                    map(lambda x: macroexpand(x, scope), sexp.list),
                )
            )
    return sexp


def sexp_list_expand(sexp_list, scope):
    return filter(
        lambda x: not x is None, map(lambda x: macroexpand(x, scope), sexp_list)
    )


def macroexpand_then_compile(sexp_list, scope=globals()):
    for k, v in globals().items():
        if not k in scope:
            scope[k] = v
    return stmt_list_compile(sexp_list_expand(sexp_list, scope))

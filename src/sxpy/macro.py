import ast
from sxpy.nodes import *
from sxpy.compiler import def_args_parse, stmt_list_compile

__macro_namespace = {}


def define_macro(sexp):
    [op, macroname, args, *body] = sexp.list
    new_name = "___macro___" + macroname.value
    def_exp = ast.FunctionDef(
        name=new_name,
        args=def_args_parse(args),
        body=macroexpand_then_compile(body),
        decorator_list=[],
        returns=None,
        **sexp.position_info
    )
    assign_exp = ast.Assign(
        targets=[
            ast.Subscript(
                value=ast.Name(
                    id="__macro_namespace", ctx=ast.Load(), **sexp.position_info
                ),
                slice=ast.Constant(value=macroname.value, **sexp.position_info),
                ctx=ast.Store(),
                **sexp.position_info
            )
        ],
        value=ast.Name(id=new_name, ctx=ast.Load(), **sexp.position_info),
        **sexp.position_info
    )
    eval(
        compile(ast.Interactive(body=[def_exp, assign_exp]), "macro-defining", "single")
    )
    return None


def macroexpand(sexp):
    if isinstance(sexp, Wrapper) or isinstance(sexp, MetaIndicator):
        sexp.value = macroexpand(sexp.value)
        _hy_anon_var_5 = sexp
    else:
        if isinstance(sexp, Expression) and len(sexp) > 0:
            [op, *operands] = sexp.list
            if str(op) == "defmacro":
                _hy_anon_var_3 = define_macro(sexp)
            else:
                if str(op) in __macro_namespace:
                    _hy_anon_var_2 = macroexpand(__macro_namespace[str(op)](*operands))
                else:
                    if True:
                        sexp.list = list(
                            filter(lambda x: not x is None, map(macroexpand, sexp.list))
                        )
                        _hy_anon_var_1 = sexp
                    else:
                        _hy_anon_var_1 = None
                    _hy_anon_var_2 = _hy_anon_var_1
                _hy_anon_var_3 = _hy_anon_var_2
            _hy_anon_var_4 = _hy_anon_var_3
        else:
            _hy_anon_var_4 = sexp if True else None
        _hy_anon_var_5 = _hy_anon_var_4
    return _hy_anon_var_5


def sexp_list_expand(sexp_list):
    return filter(lambda x: not x is None, map(macroexpand, sexp_list))


def macroexpand_then_compile(sexp_list):
    return stmt_list_compile(sexp_list_expand(sexp_list))

import ast
from collections import deque
from functools import reduce
from sxpy.compiler.expr import expr_compile, def_args_parse
from sxpy.compiler.utils import *
from sxpy.utils import *


def expr_wrapper(sexp):
    return ast.Expr(value=expr_compile(sexp), **sexp.position_info)


def do_p(sexp):
    return str(sexp.op) == "do"


def do_compile(sexp):
    [op, *sexps] = sexp.list
    return stmt_list_compile(sexps)


def assign_p(sexp):
    return str(sexp.op) == "="


def assign_compile(sexp):
    body = sexp.operands
    if isinstance(body[1], Annotation):
        [target, annotation, *value] = body
        value_dict = {"value": expr_compile(value[0])} if value else {}
        print(target, annotation, repr(target))
        _hy_anon_var_1 = ast.AnnAssign(
            target=expr_compile(target, ctx=ast.Store),
            annotation=expr_compile(annotation),
            simple=isinstance(target, Symbol) and (not "." in str(target)),
            **value_dict,
            **sexp.position_info
        )
    else:
        [*targets, value] = body
        _hy_anon_var_1 = ast.Assign(
            targets=list(map(lambda x: expr_compile(x, ctx=ast.Store), targets)),
            value=expr_compile(value),
            **sexp.position_info
        )
    return _hy_anon_var_1


def augassign_p(sexp):
    return str(sexp.op) in augassignop_dict


def augassign_compile(sexp):
    [op, target, *args] = sexp.list
    op = augassignop_dict[str(op)]
    value = reduce(
        lambda x, y: ast.BinOp(x, op(), y, **sexp.position_info),
        map(expr_compile, args),
    )
    return ast.AugAssign(
        target=expr_compile(target, ast.Store),
        op=op(),
        value=value,
        **sexp.position_info
    )


def del_compile(sexp):
    [op, *args] = sexp.list
    return ast.Delete(
        targets=list(map(lambda x: expr_compile(x, ast.Del), args)),
        **sexp.position_info
    )


def parse_names(names):
    rst = []
    q = deque(names)
    while q:
        n = q.popleft()
        if n == "as":
            rst[-1].asname = str(q.popleft())
            _hy_anon_var_2 = None
        else:
            _hy_anon_var_2 = rst.append(ast.alias(name=n.name, **n.position_info))
    return rst


def import_compile(sexp):
    [_, *names] = sexp.list
    return ast.Import(names=parse_names(names), **sexp.position_info)


def importfrom_compile(sexp):
    [_, *args] = sexp.list
    modules = args[None:None:2]
    namess = args[1:None:2]

    def _hy_anon_var_3(module):
        i = 0
        x = module.name
        while x[i] == ".":
            i += 1
        return [x[i:None:None], i, module.position_info]

    module_level = map(_hy_anon_var_3, modules)
    return [
        ast.ImportFrom(
            module=module,
            names=parse_names(names),
            level=level,
            **merge_position_infos(module_pos_info, names.position_info)
        )
        for [[module, level, module_pos_info], names] in zip(module_level, namess)
    ]


def if_p(sexp):
    return str(sexp.op) == "if"


def if_stmt_compile(sexp):
    [_, test, then, *orelse] = sexp.list
    return ast.If(
        test=expr_compile(test),
        body=stmt_list_compile([then]),
        orelse=stmt_list_compile([*orelse]),
        **sexp.position_info
    )


def while_p(sexp):
    return str(sexp.op) == "while"


def while_compile(sexp):
    [_, test, *body] = sexp.list
    lastx = body[-1]
    [then, orelse] = (
        [body[None:-1:None], lastx.operands]
        if isinstance(lastx, Paren) and lastx.op == "else"
        else [body, []]
    )
    return ast.While(
        test=expr_compile(test),
        body=stmt_list_compile(then),
        orelse=stmt_list_compile(orelse),
        **sexp.position_info
    )


def for_p(sexp):
    return str(sexp.op) == "for"


def for_compile(sexp, 𝐚sync=False):
    [_, target, iterable, *body] = sexp.list
    lastx = body[-1]
    [then, orelse] = (
        [body[None:-1:None], lastx.operands]
        if isinstance(lastx, Paren) and lastx.op == "else"
        else [body, []]
    )
    return (ast.AsyncFor if 𝐚sync else ast.For)(
        target=expr_compile(target, ast.Store),
        iter=expr_compile(iterable),
        body=stmt_list_compile(then),
        orelse=stmt_list_compile(orelse),
        **sexp.position_info
    )


def deco_p(sexp):
    return str(sexp.op) == "deco"


def raise_compile(sexp):
    body = sexp.operands
    assert len(body) == 1 or (len(body) == 3 and body[1] == "from")
    kwargs = {"exc": expr_compile(body[0])}
    if len(body) > 1:
        kwargs["cause"] = expr_compile(body[-1])
        _hy_anon_var_4 = None
    else:
        _hy_anon_var_4 = None
    return ast.Raise(**kwargs, **sexp.position_info)


def assert_compile(sexp):
    kwargs = {"test": expr_compile(sexp[1])}
    if len(sexp) > 2:
        kwargs["msg"] = expr_compile(sexp[2])
        _hy_anon_var_5 = None
    else:
        _hy_anon_var_5 = None
    return ast.Assert(**kwargs, **sexp.position_info)


def parse_exception_bracket(bracket):
    lst = bracket.list
    name = str([lst.pop(), lst.pop()][0]) if len(lst) > 2 and lst[-2] == "as" else None
    type = (
        ast.Tuple(
            elts=list(map(expr_compile, lst)), ctx=ast.Load(), **bracket.position_info
        )
        if len(lst) > 1
        else expr_compile(lst[0])
    )
    return [type, name]


def parse_except(handler):
    body = handler.operands
    if isinstance(body[0], Bracket):
        body = deque(handler.operands)
        _hy_anon_var_6 = parse_exception_bracket(body.popleft())
    else:
        _hy_anon_var_6 = [None, None]
    [type, name] = _hy_anon_var_6
    kwargs = {"body": stmt_list_compile(body)}
    if type:
        kwargs["type"] = type
        _hy_anon_var_7 = None
    else:
        _hy_anon_var_7 = None
    if name:
        kwargs["name"] = name
        _hy_anon_var_8 = None
    else:
        _hy_anon_var_8 = None
    return ast.ExceptHandler(**kwargs, **handler.position_info)


def try_compile(sexp):
    body = sexp.operands
    finalbody = (
        body.pop().operands
        if isinstance(body[-1], Paren) and body[-1].op == "finally"
        else []
    )
    orelse = (
        body.pop().operands
        if isinstance(body[-1], Paren) and body[-1].op == "else"
        else []
    )
    handlers = deque()
    while isinstance(body[-1], Paren) and body[-1].op == "except":
        handlers.appendleft(body.pop())
    handlers = list(map(parse_except, handlers))
    starhandlers = deque()
    while isinstance(body[-1], Paren) and body[-1].op == "except*":
        starhandlers.appendleft(body.pop())
    starhandlers = list(map(parse_except, starhandlers))
    assert not starhandlers or not handlers
    return (ast.Try if not starhandlers else ast.TryStar)(
        body=stmt_list_compile(body),
        handlers=handlers or starhandlers,
        orelse=stmt_list_compile(orelse),
        finalbody=stmt_list_compile(finalbody),
        **sexp.position_info
    )


def with_items_parse(sexp):
    rst = []
    q = deque(sexp.list)
    while q:
        elt = q.popleft()
        if str(elt) == "as":
            rst[-1].optional_vars = expr_compile(q.popleft(), ctx=ast.Store)
            _hy_anon_var_9 = None
        else:
            _hy_anon_var_9 = rst.append(ast.withitem(context_expr=expr_compile(elt)))
    return rst


def with_compile(sexp, 𝐚sync=False):
    [bracket_sexp, *body] = sexp.operands
    items = with_items_parse(bracket_sexp)
    return (ast.AsyncWith if 𝐚sync else ast.With)(
        items=items, body=stmt_list_compile(body), **sexp.position_info
    )


def match_mapping_parse(lst):
    keys = lst[None:None:2]
    patterns = lst[1:None:2]
    rst = {}
    if isinstance(keys[-1], DoubleStarred):
        rst["rest"] = keys.pop().value.name
        _hy_anon_var_10 = None
    else:
        _hy_anon_var_10 = None
    rst["keys"] = list(map(expr_compile, keys))
    rst["patterns"] = list(map(pattern_parse, patterns))
    return rst


def match_class_parse(lst):
    q = deque(lst)
    patterns = []
    kwd_attrs = []
    kwd_patterns = []
    while q:
        arg = q.popleft()
        if isinstance(arg, Keyword):
            kwd_attrs.append(arg.value.name)
            _hy_anon_var_11 = kwd_patterns.append(pattern_parse(q.popleft()))
        else:
            _hy_anon_var_11 = patterns.append(pattern_parse(arg))
    return {"patterns": patterns, "kwd_attrs": kwd_attrs, "kwd_patterns": kwd_patterns}


def pattern_parse(sexp):
    return (
        ast.MatchAs(**sexp.position_info)
        if str(sexp) == "_"
        else ast.MatchAs(name=sexp.name, **sexp.position_info)
        if isinstance(sexp, Symbol)
        else ast.MatchSingleton(value=eval(str(sexp)), **sexp.position_info)
        if str(sexp) in ["True", "False", "None"]
        else ast.MatchStar(
            **{} if str(sexp.value) == "_" else {"name": sexp.value.name},
            **sexp.position_info
        )
        if isinstance(sexp, Starred)
        else ast.MatchValue(value=expr_compile(sexp), **sexp.position_info)
        if not isinstance(sexp, Expression)
        else ast.MatchSequence(
            patterns=list(map(pattern_parse, sexp.list)), **sexp.position_info
        )
        if isinstance(sexp, Bracket)
        else ast.MatchMapping(**match_mapping_parse(sexp.list), **sexp.position_info)
        if isinstance(sexp, Brace)
        else ast.MatchOr(
            patterns=list(map(pattern_parse, sexp.operands)), **sexp.position_info
        )
        if sexp.op == "|"
        else ast.MatchClass(
            cls=expr_compile(sexp.op),
            **match_class_parse(sexp.operands),
            **sexp.position_info
        )
        if True
        else None
    )


def case_parse(case):
    [pattern_expr, *body] = case.operands
    pattern = pattern_parse(pattern_expr)
    if body[0] == "as":
        pattern = ast.MatchAs(
            pattern=pattern,
            name=body[1].name,
            **merge_position_infos(pattern_expr.position_info, body[1].position_info)
        )
        body = body[2:None:None]
        _hy_anon_var_12 = None
    else:
        _hy_anon_var_12 = None
    if body[0] == "if":
        guard_dict = {"guard": expr_compile(body[1])}
        body = body[2:None:None]
        _hy_anon_var_13 = None
    else:
        guard_dict = {}
        _hy_anon_var_13 = None
    return ast.match_case(pattern=pattern, **guard_dict, body=stmt_list_compile(body))


def match_compile(sexp):
    [subject, *cases] = sexp.operands
    cases = list(map(case_parse, cases))
    return ast.Match(subject=expr_compile(subject), cases=cases, **sexp.position_info)


def deco_compile(sexp, decorator_list):
    [op, decorator, def_statement] = sexp.list
    new_deco_list = decorator.list if isinstance(decorator, Bracket) else [decorator]
    return stmt_compile(
        def_statement, (decorator_list if decorator_list else []) + new_deco_list
    )


def functiondef_p(sexp):
    return str(sexp.op) == "def"


def functiondef_compile(sexp, decorator_list, 𝐚sync=False):
    [op, fnname, args, *body] = sexp.list
    if body and isinstance(body[0], Annotation):
        [ann, *body] = body
        _hy_anon_var_14 = None
    else:
        ann = None
        _hy_anon_var_14 = None
    return (ast.AsyncFunctionDef if 𝐚sync else ast.FunctionDef)(
        name=fnname.name,
        args=def_args_parse(args),
        body=stmt_list_compile(body),
        decorator_list=list(map(expr_compile, decorator_list))
        if decorator_list
        else [],
        returns=expr_compile(ann.value) if ann else None,
        **sexp.position_info
    )


def return_p(sexp):
    return str(sexp.op) == "return"


def return_compile(sexp):
    [op, value] = sexp.list
    return ast.Return(value=expr_compile(value), **sexp.position_info)


def global_compile(sexp):
    [_, *args] = sexp.list
    return ast.Global(names=list(map(lambda x: x.name, args)), **sexp.position_info)


def nonlocal_compile(sexp):
    [_, *args] = sexp.list
    return ast.Nonlocal(names=list(map(lambda x: x.name, args)), **sexp.position_info)


def classdef_p(sexp):
    return str(sexp.op) == "class"


def classdef_args_parse(args):
    q = deque(args)
    bases = []
    keywords = []
    while q:
        arg = q.popleft()
        keywords.append(
            ast.keyword(
                arg=arg.name, value=expr_compile(q.popleft()), **arg.position_info
            )
        ) if keyword_arg_p(arg) else bases.append(expr_compile(arg))
    return [bases, keywords]


def classdef_compile(sexp, decorator_list):
    [_, clsname, args, *body] = sexp.list
    [bases, keywords] = classdef_args_parse(args)
    return ast.ClassDef(
        name=clsname.name,
        bases=bases,
        keywords=keywords,
        body=stmt_list_compile(body),
        decorator_list=list(map(expr_compile, decorator_list))
        if decorator_list
        else [],
        **sexp.position_info
    )


def stmt_compile(sexp, decorator_list=None):
    return (
        expr_wrapper(sexp)
        if not paren_p(sexp)
        else do_compile(sexp)
        if do_p(sexp)
        else assign_compile(sexp)
        if assign_p(sexp)
        else augassign_compile(sexp)
        if augassign_p(sexp)
        else del_compile(sexp)
        if str(sexp.op) == "del"
        else ast.Pass(**sexp.position_info)
        if str(sexp.op) == "pass"
        else import_compile(sexp)
        if str(sexp.op) == "import"
        else importfrom_compile(sexp)
        if str(sexp.op) == "from"
        else if_stmt_compile(sexp)
        if if_p(sexp)
        else while_compile(sexp)
        if while_p(sexp)
        else for_compile(sexp)
        if for_p(sexp)
        else ast.Break(**sexp.position_info)
        if str(sexp.op) == "break"
        else ast.Continue(**sexp.position_info)
        if str(sexp.op) == "continue"
        else raise_compile(sexp)
        if str(sexp.op) == "raise"
        else assert_compile(sexp)
        if str(sexp.op) == "assert"
        else try_compile(sexp)
        if str(sexp.op) == "try"
        else with_compile(sexp)
        if str(sexp.op) == "with"
        else match_compile(sexp)
        if str(sexp.op) == "match"
        else deco_compile(sexp, decorator_list)
        if deco_p(sexp)
        else functiondef_compile(sexp, decorator_list)
        if functiondef_p(sexp)
        else return_compile(sexp)
        if return_p(sexp)
        else global_compile(sexp)
        if str(sexp.op) == "global"
        else nonlocal_compile(sexp)
        if str(sexp.op) == "nonlocal"
        else classdef_compile(sexp, decorator_list)
        if classdef_p(sexp)
        else functiondef_compile(sexp, decorator_list, 𝐚sync=True)
        if str(sexp.op) == "async-def"
        else with_compile(sexp, 𝐚sync=True)
        if str(sexp.op) == "async-for"
        else with_compile(sexp, 𝐚sync=True)
        if str(sexp.op) == "async-with"
        else expr_wrapper(sexp)
        if True
        else None
    )


def stmt_list_compile(sexp_list):
    return reduce(
        lambda x, y: x + (y if isinstance(y, list) else [y]),
        map(stmt_compile, sexp_list),
        [],
    )

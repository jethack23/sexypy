import re
from collections import deque
from functools import reduce

from sxpy.nodes import *
from sxpy.utils import augassignop_dict


def tokenize(src):
    lines = src.split("\n")
    tokens = deque([])
    int_simple = "\\d+(?:_\\d+)*"
    float_simples = [
        "\\d+(?:_\\d+)*\\.\\d+(?:_\\d+)*",
        "\\d+(?:_\\d+)*\\.\\d*",
        "\\d*\\.\\d+(?:_\\d+)*",
    ]
    scientific_simples = list(
        map(lambda x: x + "e[\\-\\+]?\\d+(?:_\\d+)*", float_simples + [int_simple])
    )
    number_simple = "|".join(scientific_simples + float_simples + [int_simple])
    complex_simple = f"(?:(?:{number_simple})[+-])?(?:{number_simple})j"
    pattern_labels = [
        ["\\^?\\*{0,2}[\\(\\{\\[]", "opening"],
        ["[\\)\\}\\]]", "closing"],
        *list(
            zip(
                map(
                    lambda x: "\\w*" + x,
                    [
                        "\\'\\'\\'(?:[^\\\\']|\\\\.)*\\'\\'\\'",
                        '\\"\\"\\"(?:[^\\\\\\"]|\\\\.)*\\"\\"\\"',
                        '\\"(?:[^\\\\\\"]|\\\\.)*\\"',
                    ],
                ),
                ["'''", '"""', '"'],
            )
        ),
        ["(?:'|`|~@|~)(?!\\s|$)", "meta-indicator"],
        [";[^\\n]*", "comment"],
        [
            "[+-]*(?:"
            + "|".join([complex_simple, number_simple])
            + ")(?=\\s|$|\\)|\\}|\\])",
            "number",
        ],
        ['[^\\s\\)\\}\\]\\"]+', "symbol"],
        ["\\n", "new-line"],
        [" +", "spaces"],
    ]
    [patterns, labels] = zip(*pattern_labels)
    combined_pattern = "|".join(map(lambda p: f"({p})", patterns))
    lineno = 1
    col_offset = 0
    re_applied = reduce(
        lambda x, y: x + y,
        map(
            lambda x: list(filter(lambda y: y[0], zip(x, labels))),
            re.findall(combined_pattern, src),
        ),
        [],
    )
    for [tk, tktype] in re_applied:
        splitted = tk.split("\n")
        [num_newline, col_shift] = [len(splitted) - 1, len(splitted[-1])]
        end_lineno = lineno + num_newline
        end_col_offset = col_shift + (col_offset if num_newline == 0 else 0)
        tokens.append(
            [
                tk,
                tktype,
                {
                    "lineno": lineno,
                    "col_offset": col_offset,
                    "end_lineno": end_lineno,
                    "end_col_offset": end_col_offset,
                },
            ]
        ) if not tktype in ["new-line", "spaces", "comment"] else None
        lineno = end_lineno
        col_offset = end_col_offset
    return tokens


def position_info_into_list(position_info):
    return list(
        map(
            lambda x: position_info[x],
            ["lineno", "col_offset", "end_lineno", "end_col_offset"],
        )
    )


opening_prefix_dict = {
    "": lambda value, **kwargs: value,
    "*": Starred,
    "**": DoubleStarred,
    "^": Annotation,
}
opening_dict = {"(": Paren, "{": Brace, "[": Bracket}
meta_indicator_dict = {"'": Quote, "`": QuasiQuote, "~": Unquote, "~@": UnquoteSplice}


def parse(src):
    tokens = tokenize(src)
    stack = []
    rst = []
    while tokens:
        [t, tktype, position_info] = tokens.popleft()
        [lineno, col_offset, end_lineno, end_col_offset] = position_info_into_list(
            position_info
        )
        if tktype == "opening":
            _hy_anon_var_4 = stack.append(
                opening_prefix_dict[t[None:-1:None]](
                    value=opening_dict[t[-1]](
                        lineno=lineno, col_offset=col_offset + (len(t) - 1)
                    ),
                    lineno=lineno,
                    col_offset=col_offset,
                )
            )
        else:
            if tktype == "meta-indicator":
                _hy_anon_var_3 = stack.append(
                    meta_indicator_dict[t](
                        value=None, lineno=lineno, col_offset=col_offset
                    )
                )
            else:
                if True:
                    if tktype == "closing":
                        e = stack.pop()
                        e.update_dict("end_lineno", end_lineno)
                        _hy_anon_var_1 = e.update_dict("end_col_offset", end_col_offset)
                    else:
                        e = token_parse(t, tktype, position_info)
                        _hy_anon_var_1 = None
                    while stack and isinstance(stack[-1], MetaIndicator):
                        popped = stack.pop()
                        popped.value = e
                        popped.update_dict("end_lineno", end_lineno)
                        popped.update_dict("end_col_offset", end_col_offset)
                        e = popped
                    _hy_anon_var_2 = (stack[-1] if stack else rst).append(e)
                else:
                    _hy_anon_var_2 = None
                _hy_anon_var_3 = _hy_anon_var_2
            _hy_anon_var_4 = _hy_anon_var_3
    return rst


special_literals = ("True", "False", "None", "...")


def token_parse(token, tktype, position_info):
    return (
        Symbol(token, **position_info)
        if token in augassignop_dict
        else Constant(token, **position_info)
        if token in special_literals
        else Constant(token, **position_info)
        if tktype == "number" and (not token[0] in "+-")
        else string_parse(token, tktype, position_info)
        if tktype in ["'''", '"""', '"']
        else Symbol(token, **position_info)
        if len(token) < 2
        else annotation_token_parse(token, tktype, position_info)
        if token[0] == "^"
        else keyword_token_parse(token, tktype, position_info)
        if token[0] == ":"
        else star_token_parse(token, tktype, position_info)
        if token[0] == "*"
        else unary_op_parse(token, tktype, position_info)
        if token[0] in "+-"
        else Symbol(token, **position_info)
        if True
        else None
    )


def annotation_token_parse(token, tktype, position_info):
    inner_position = {**position_info}
    inner_position["col_offset"] += 1
    return Annotation(
        token_parse(token[1:None:None], tktype, inner_position), **position_info
    )


def keyword_token_parse(token, tktype, position_info):
    inner_position = {**position_info}
    inner_position["col_offset"] += 1
    return Keyword(
        token_parse(token[1:None:None], tktype, inner_position), **position_info
    )


def star_token_parse(token, tktype, position_info):
    num_star = 2 if token[1] == "*" else 1
    inner_position = {**position_info}
    inner_position["col_offset"] += num_star
    return opening_prefix_dict["*" * num_star](
        token_parse(token[slice(num_star, None)], tktype, inner_position),
        **position_info,
    )


def unary_op_parse(token, tktype, position_info):
    stack = []
    idx = 0
    lineno = position_info["lineno"]
    col_offset = position_info["col_offset"]
    while token[idx] in "+-":
        stack.append(
            Symbol(
                token[idx],
                **{
                    "lineno": lineno,
                    "end_lineno": lineno,
                    "col_offset": col_offset + idx,
                    "end_col_offset": col_offset + idx + 1,
                },
            )
        )
        idx += 1
    position_info["col_offset"] += idx
    rst = token_parse(token[slice(idx, None)], tktype, {**position_info})
    while stack:
        position_info["col_offset"] -= 1
        rst = Paren(stack.pop(), rst, **position_info)
    return rst


def string_parse(token, tktype, position_info):
    [prefix, *contents, _] = token.split(tktype)
    return (
        f_string_parse(
            prefix.replace("f", ""), tktype.join(contents), tktype, position_info
        )
        if "f" in prefix
        else String(token, **position_info)
    )


conversion_dict = {"!s": 115, "!r": 114, "!a": 97}


def f_string_parse(prefix, content, tktype, position_info):
    splitted = re.split("[\\{\\}]", content)
    processed = []
    splitted.pop() if splitted[-1] == "" else None
    for [i, piece] in enumerate(splitted):
        if i % 2:
            if ":" in piece:
                [*quarks, format_spec] = piece.split(":")
                piece = ":".join(quarks)
                _hy_anon_var_5 = None
            else:
                format_spec = None
                _hy_anon_var_5 = None
            if piece[-2:None:None] in conversion_dict:
                conversion = conversion_dict[piece[-2:None:None]]
                piece = piece[None:-2:None]
                _hy_anon_var_6 = None
            else:
                conversion = -1
                _hy_anon_var_6 = None
            _hy_anon_var_7 = processed.append(
                FStrExpr(
                    parse(piece).pop(),
                    conversion=conversion,
                    format_spec=format_spec,
                    **position_info,
                )
            )
        else:
            _hy_anon_var_7 = processed.append(
                string_parse(prefix + tktype + piece + tktype, tktype, position_info)
            )
    return Paren(Symbol("f-string", **position_info), *processed)

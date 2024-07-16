import ast


def constant_compile(constant):
    return ast.Constant(value=eval(constant.value), **constant.position_info)


def string_compile(string):
    return ast.Constant(
        value=eval(string.value.replace("\r\n", "\\n").replace("\n", "\\n")),
        **string.position_info
    )


def name_compile(symbol, ctx):
    [name, *attrs] = symbol.name.replace("-", "_").split(".")
    # it's not name. it's a number but not captured with nubmer regex
    if name.startswith("0x"):
        assert ctx == ast.Load
        symbol.value = str(int(name, 16))
        return constant_compile(symbol)
    elif name.startswith("0o"):
        assert ctx == ast.Load
        symbol.value = str(int(name, 8))
        return constant_compile(symbol)
    elif name.startswith("0b"):
        assert ctx == ast.Load
        symbol.value = str(int(name, 2))
        return constant_compile(symbol)
    position_info = {**symbol.position_info}
    position_info["end_col_offset"] = position_info["col_offset"] + len(name)
    rst = ast.Name(id=name, ctx=ast.Load(), **position_info)
    for attr in attrs:
        position_info["end_col_offset"] += 1 + len(attr)
        rst = ast.Attribute(value=rst, attr=attr, ctx=ast.Load(), **position_info)
    rst.ctx = ctx()
    return rst

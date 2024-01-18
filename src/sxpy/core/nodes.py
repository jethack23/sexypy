class Node:
    def __init__(self, *args, **kwargs):
        self.lineno = 0
        self.col_offset = 0
        self.end_lineno = 0
        self.end_col_offset = 0
        for [k, v] in kwargs.items():
            self.__dict__[k] = v

    def update_dict(self, key, value):
        self.__dict__[key] = value

    @property
    def position_info(self):
        return {
            "lineno": self.lineno,
            "end_lineno": self.end_lineno,
            "col_offset": self.col_offset,
            "end_col_offset": self.end_col_offset,
        }

    def _generator_expression(self, in_quasi):
        return Paren(
            Symbol(self.classname, **self.position_info),
            self.operands_generate(in_quasi),
            **self.position_info
        )

    def generator_expression(self, in_quasi=False):
        return self._generator_expression(in_quasi)

    def __eq__(self, other):
        return str(self) == other


class Expression(Node):
    def __init__(self, *tokens, **kwargs):
        super().__init__(**kwargs)
        self.list = list(tokens)

    def append(self, t):
        return self.list.append(t)

    def operands_generate(self, in_quasi):
        return [sexp.generator_expression(in_quasi) for sexp in self.list]

    def generator_expression(self, in_quasi=False):
        return Paren(
            Symbol(self.classname, **self.position_info),
            *self.operands_generate(in_quasi),
            **self.position_info
        )

    def __repr__(self, depth=0):
        return "Expr(" + ", ".join([repr(e) for e in self.list]) + ")"

    def __iter__(self):
        return iter(self.list)

    def __getitem__(self, idx):
        return self.list[idx]

    def __len__(self):
        return len(self.list)

    @property
    def op(self):
        return self.list[0]

    @property
    def operands(self):
        return self.list[slice(1, None)]


openings = {"Paren": "(", "Bracket": "[", "Brace": "{"}
closings = {"Paren": ")", "Bracket": "]", "Brace": "}"}


class Paren(Expression):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.classname = "Paren"

    def __repr__(self, depth=0):
        return "Paren" + "(" + ", ".join([repr(e) for e in self.list]) + ")"

    def __str__(self):
        return (
            openings["Paren"]
            + " ".join([str(e) for e in self.list])
            + closings["Paren"]
        )


class Bracket(Expression):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.classname = "Bracket"

    def __repr__(self, depth=0):
        return "Bracket" + "(" + ", ".join([repr(e) for e in self.list]) + ")"

    def __str__(self):
        return (
            openings["Bracket"]
            + " ".join([str(e) for e in self.list])
            + closings["Bracket"]
        )


class Brace(Expression):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.classname = "Brace"

    def __repr__(self, depth=0):
        return "Brace" + "(" + ", ".join([repr(e) for e in self.list]) + ")"

    def __str__(self):
        return (
            openings["Brace"]
            + " ".join([str(e) for e in self.list])
            + closings["Brace"]
        )


class Wrapper(Node):
    def operands_generate(self, in_quasi):
        return self.value.generator_expression(in_quasi)


class FStrExpr(Wrapper):
    def __init__(self, value, **kwargs):
        super().__init__(**kwargs)
        self.value = value
        self.classname = "FStrExpr"

    def __repr__(self):
        return "FStrExpr(" + repr(self.value) + ")"

    def __str__(self):
        return "(FStrExpr " + str(self.value) + ")"

    @property
    def name(self):
        return self.value.name

    def update_dict(self, key, value):
        self.__dict__[key] = value
        return self.value.update_dict(key, value)


class Annotation(Wrapper):
    def __init__(self, value, **kwargs):
        super().__init__(**kwargs)
        self.value = value
        self.classname = "Annotation"

    def __repr__(self):
        return "Ann(" + repr(self.value) + ")"

    def __str__(self):
        return "^" + str(self.value)

    def append(self, e):
        return self.value.append(e)

    @property
    def name(self):
        return self.value.name

    def update_dict(self, key, value):
        self.__dict__[key] = value
        return self.value.update_dict(key, value)


class Keyword(Wrapper):
    def __init__(self, value, **kwargs):
        super().__init__(**kwargs)
        self.value = value
        self.classname = "Keyword"

    def __repr__(self):
        return "Kwd(" + repr(self.value) + ")"

    def __str__(self):
        return ":" + str(self.value)

    @property
    def name(self):
        return self.value.name

    def update_dict(self, key, value):
        self.__dict__[key] = value
        return self.value.update_dict(value)


class Starred(Wrapper):
    def __init__(self, value, **kwargs):
        super().__init__(**kwargs)
        self.value = value
        self.classname = "Starred"

    def __repr__(self):
        return "Star(" + repr(self.value) + ")"

    def __str__(self):
        return "*" + str(self.value)

    def append(self, e):
        return self.value.append(e)

    def update_dict(self, key, value):
        self.__dict__[key] = value
        return self.value.update_dict(key, value)


class DoubleStarred(Wrapper):
    def __init__(self, value, **kwargs):
        super().__init__(**kwargs)
        self.value = value
        self.classname = "DoubleStarred"

    def __repr__(self):
        return "DStar(" + repr(self.value) + ")"

    def __str__(self):
        return "**" + str(self.value)

    def append(self, e):
        return self.value.append(e)

    def update_dict(self, key, value):
        self.__dict__[key] = value
        return self.value.update_dict(key, value)


class Literal(Node):
    def operands_generate(self, in_quasi):
        return String('"' + self.value + '"', **self.position_info)


class Symbol(Literal):
    def __init__(self, value, **kwargs):
        super().__init__(**kwargs)
        self.value = value
        self.classname = "Symbol"

    @property
    def name(self):
        return self.value.replace("-", "_")

    def __repr__(self):
        return "Sym(" + self.value + ")"

    def __str__(self):
        return self.value


class String(Literal):
    def __init__(self, value, **kwargs):
        super().__init__(**kwargs)
        self.value = value
        self.classname = "String"

    def operands_generate(self, in_quasi):
        return String(
            '"' + self.value.replace("\\", "\\\\").replace('"', '\\"') + '"',
            **self.position_info
        )

    def __repr__(self):
        return "Str(" + repr(self.value) + ")"

    def __str__(self):
        return self.value


class Constant(Literal):
    def __init__(self, value, **kwargs):
        super().__init__(**kwargs)
        self.value = value
        self.classname = "Constant"

    def __repr__(self):
        return "Const(" + repr(self.value) + ")"

    def __str__(self):
        return str(self.value).replace("'", "")


class MetaIndicator(Node):
    def __init__(self, value, **kwargs):
        super().__init__(**kwargs)
        self.value = value

    def operands_generate(self, in_quasi):
        return self.value.operands_generate(isinstance(self, QuasiQuote))


class Quote(MetaIndicator):
    def __init__(self, value, **kwargs):
        super().__init__(value, **kwargs)
        self.classname = "Quote"

    def __repr__(self):
        return "Quote(" + repr(self.value) + ")"

    def __str__(self):
        return "'" + str(self.value)


class QuasiQuote(Quote):
    def __init__(self, value, **kwargs):
        super().__init__(value, **kwargs)
        self.classname = "QuasiQuote"

    def __repr__(self):
        return "QuasiQuote(" + repr(self.value) + ")"

    def __str__(self):
        return "`" + str(self.value)


class Unquote(MetaIndicator):
    def __init__(self, value, **kwargs):
        super().__init__(value, **kwargs)
        self.classname = "Unquote"

    def generator_expression(self, in_quasi=False):
        return self.value if in_quasi else self._generator_expression(False)

    def __repr__(self):
        return "Unquote(" + repr(self.value) + ")"

    def __str__(self):
        return "~" + str(self.value)


class UnquoteSplice(Unquote):
    def __init__(self, value, **kwargs):
        super().__init__(value, **kwargs)
        self.classname = "UnquoteSplice"

    def generator_expression(self, in_quasi=False):
        return (
            Starred(self.value, **self.position_info)
            if in_quasi
            else self._generator_expression(False)
        )

    def __repr__(self):
        return "UnquoteSplice(" + repr(self.value) + ")"

    def __str__(self):
        return "~@" + str(self.value)

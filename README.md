# SexyPy : the Most Nerdy Python Ever!
SexyPy stands for **S-ex**_pression-ish(_**y**_)_ **Py**_thon_.   
Highly inspired by Clojure and Hy.   
Once I loved to use Hy when I need to use python. But as I started to learn Clojure, similarity between two languages confused me. I want a language more straightforward to being python but in S-expression so that I can exploit structural editing and metaprogramming by macro. Thus I decided to start this project.

# Run REPL
```bash
hy -m sexypy.repl
#or
python -m sexypy.repl
```

# Run Tests
```bash
# in project root directory
python -m unittest
#or
hy -m unittest
```


# AST todo
```
mod = Module(stmt* body, type_ignore* type_ignores)
    | Interactive(stmt* body)
    | Expression(expr body)
    | FunctionType(expr* argtypes, expr returns)

stmt = Match(expr subject, match_case* cases)

        -- col_offset is the byte offset in the utf8 string the parser uses
        attributes (int lineno, int col_offset, int? end_lineno, int? end_col_offset)

expr = FormattedValue(expr value, int conversion, expr? format_spec)
        | JoinedStr(expr* values)

        -- col_offset is the byte offset in the utf8 string the parser uses
        attributes (int lineno, int col_offset, int? end_lineno, int? end_col_offset)

match_case = (pattern pattern, expr? guard, stmt* body)

pattern = MatchValue(expr value)
        | MatchSingleton(constant value)
        | MatchSequence(pattern* patterns)
        | MatchMapping(expr* keys, pattern* patterns, identifier? rest)
        | MatchClass(expr cls, pattern* patterns, identifier* kwd_attrs, pattern* kwd_patterns)

        | MatchStar(identifier? name)
        -- The optional "rest" MatchMapping parameter handles capturing extra mapping keys

        | MatchAs(pattern? pattern, identifier? name)
        | MatchOr(pattern* patterns)

            attributes (int lineno, int col_offset, int end_lineno, int end_col_offset)

type_ignore = TypeIgnore(int lineno, string tag)
```

Implemented Components are removed   
- type_comment never considered. Later, it should be covered
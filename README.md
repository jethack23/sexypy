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
<pre class="nimrod hljs" style="text-align: start;" data-mce-style="background-color: #f8f8f8; color: #000000; text-align: start;" contenteditable="false" data-mce-selected="1">-- <span class="hljs-type">ASDL</span>'s <span class="hljs-number">4</span> builtin types are:
-- identifier, <span class="hljs-built_in">int</span>, <span class="hljs-built_in">string</span>, constant

module <span class="hljs-type">Python</span>
{
    <span class="hljs-keyword">mod</span> = <span class="hljs-type">Module</span>(<span class="hljs-built_in">stmt</span>* body, type_ignore* type_ignores)
        | <span class="hljs-type">Interactive</span>(<span class="hljs-built_in">stmt</span>* body)
        | <span class="hljs-type">Expression</span>(<span class="hljs-built_in">expr</span> body)
        | <span class="hljs-type">FunctionType</span>(<span class="hljs-built_in">expr</span>* argtypes, <span class="hljs-built_in">expr</span> returns)

    <span class="hljs-built_in">stmt</span> = <span class="hljs-type">FunctionDef</span>(identifier name, arguments args,
                       <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">expr</span>* decorator_list, <span class="hljs-built_in">expr</span>? returns,
                       <span class="hljs-built_in">string</span>? type_comment, type_param* type_params)
          | <span class="hljs-type">AsyncFunctionDef</span>(identifier name, arguments args,
                             <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">expr</span>* decorator_list, <span class="hljs-built_in">expr</span>? returns,
                             <span class="hljs-built_in">string</span>? type_comment, type_param* type_params)

          | <span class="hljs-type">ClassDef</span>(identifier name,
             <span class="hljs-built_in">expr</span>* bases,
             keyword* keywords,
             <span class="hljs-built_in">stmt</span>* body,
             <span class="hljs-built_in">expr</span>* decorator_list,
             type_param* type_params)
          | <span class="hljs-type">Return</span>(<span class="hljs-built_in">expr</span>? value)

          | <span class="hljs-type">Delete</span>(<span class="hljs-built_in">expr</span>* targets)
          | <span class="hljs-type">Assign</span>(<span class="hljs-built_in">expr</span>* targets, <span class="hljs-built_in">expr</span> value, <span class="hljs-built_in">string</span>? type_comment)
          | <span class="hljs-type">TypeAlias</span>(<span class="hljs-built_in">expr</span> name, type_param* type_params, <span class="hljs-built_in">expr</span> value)
          | <span class="hljs-type">AugAssign</span>(<span class="hljs-built_in">expr</span> target, operator op, <span class="hljs-built_in">expr</span> value)
          -- 'simple' indicates that we annotate simple name <span class="hljs-keyword">without</span> parens
          | <span class="hljs-type">AnnAssign</span>(<span class="hljs-built_in">expr</span> target, <span class="hljs-built_in">expr</span> annotation, <span class="hljs-built_in">expr</span>? value, <span class="hljs-built_in">int</span> simple)

          -- use 'orelse' because <span class="hljs-keyword">else</span> <span class="hljs-keyword">is</span> a keyword <span class="hljs-keyword">in</span> target languages
          | <span class="hljs-type">For</span>(<span class="hljs-built_in">expr</span> target, <span class="hljs-built_in">expr</span> iter, <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">stmt</span>* orelse, <span class="hljs-built_in">string</span>? type_comment)
          | <span class="hljs-type">AsyncFor</span>(<span class="hljs-built_in">expr</span> target, <span class="hljs-built_in">expr</span> iter, <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">stmt</span>* orelse, <span class="hljs-built_in">string</span>? type_comment)
          | <span class="hljs-type">While</span>(<span class="hljs-built_in">expr</span> test, <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">stmt</span>* orelse)
          | <span class="hljs-type">If</span>(<span class="hljs-built_in">expr</span> test, <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">stmt</span>* orelse)
          | <span class="hljs-type">With</span>(withitem* items, <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">string</span>? type_comment)
          | <span class="hljs-type">AsyncWith</span>(withitem* items, <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">string</span>? type_comment)

          | <span class="hljs-type">Match</span>(<span class="hljs-built_in">expr</span> subject, match_case* cases)

          | <span class="hljs-type">Raise</span>(<span class="hljs-built_in">expr</span>? exc, <span class="hljs-built_in">expr</span>? cause)
          | <span class="hljs-type">Try</span>(<span class="hljs-built_in">stmt</span>* body, excepthandler* handlers, <span class="hljs-built_in">stmt</span>* orelse, <span class="hljs-built_in">stmt</span>* finalbody)
          | <span class="hljs-type">TryStar</span>(<span class="hljs-built_in">stmt</span>* body, excepthandler* handlers, <span class="hljs-built_in">stmt</span>* orelse, <span class="hljs-built_in">stmt</span>* finalbody)
          | <span class="hljs-type">Assert</span>(<span class="hljs-built_in">expr</span> test, <span class="hljs-built_in">expr</span>? msg)

          | <span class="hljs-type">Import</span>(alias* names)
          | <span class="hljs-type">ImportFrom</span>(identifier? module, alias* names, <span class="hljs-built_in">int</span>? level)

          | <span class="hljs-type">Global</span>(identifier* names)
          | <span class="hljs-type">Nonlocal</span>(identifier* names)
          | <span class="hljs-type">Expr</span>(<span class="hljs-built_in">expr</span> value)
          | <span class="hljs-type">Pass</span> | <span class="hljs-type">Break</span> | <span class="hljs-type">Continue</span>

          -- col_offset <span class="hljs-keyword">is</span> the byte offset <span class="hljs-keyword">in</span> the utf8 <span class="hljs-built_in">string</span> the parser uses
          attributes (<span class="hljs-built_in">int</span> lineno, <span class="hljs-built_in">int</span> col_offset, <span class="hljs-built_in">int</span>? end_lineno, <span class="hljs-built_in">int</span>? end_col_offset)

          -- <span class="hljs-type">BoolOp</span>() can use left &amp; right?
    <span class="hljs-built_in">expr</span> = <span class="hljs-type">NamedExpr</span>(<span class="hljs-built_in">expr</span> target, <span class="hljs-built_in">expr</span> value)
         | <span class="hljs-type">Lambda</span>(arguments args, <span class="hljs-built_in">expr</span> body)
         | <span class="hljs-type">IfExp</span>(<span class="hljs-built_in">expr</span> test, <span class="hljs-built_in">expr</span> body, <span class="hljs-built_in">expr</span> orelse)
         | <span class="hljs-type">Dict</span>(<span class="hljs-built_in">expr</span>* keys, <span class="hljs-built_in">expr</span>* values)
         | <span class="hljs-type">Set</span>(<span class="hljs-built_in">expr</span>* elts)
         | <span class="hljs-type">ListComp</span>(<span class="hljs-built_in">expr</span> elt, comprehension* generators)
         | <span class="hljs-type">SetComp</span>(<span class="hljs-built_in">expr</span> elt, comprehension* generators)
         | <span class="hljs-type">DictComp</span>(<span class="hljs-built_in">expr</span> key, <span class="hljs-built_in">expr</span> value, comprehension* generators)
         | <span class="hljs-type">GeneratorExp</span>(<span class="hljs-built_in">expr</span> elt, comprehension* generators)
         -- the grammar constrains where <span class="hljs-keyword">yield</span> expressions can occur
         | <span class="hljs-type">Await</span>(<span class="hljs-built_in">expr</span> value)
         | <span class="hljs-type">Yield</span>(<span class="hljs-built_in">expr</span>? value)
         | <span class="hljs-type">YieldFrom</span>(<span class="hljs-built_in">expr</span> value)
         -- need sequences <span class="hljs-keyword">for</span> compare to distinguish between
         -- x &lt; <span class="hljs-number">4</span> &lt; <span class="hljs-number">3</span> <span class="hljs-keyword">and</span> (x &lt; <span class="hljs-number">4</span>) &lt; <span class="hljs-number">3</span>
         | <span class="hljs-type">Compare</span>(<span class="hljs-built_in">expr</span> left, cmpop* ops, <span class="hljs-built_in">expr</span>* comparators)
         | <span class="hljs-type">Call</span>(<span class="hljs-built_in">expr</span> func, <span class="hljs-built_in">expr</span>* args, keyword* keywords)
         | <span class="hljs-type">FormattedValue</span>(<span class="hljs-built_in">expr</span> value, <span class="hljs-built_in">int</span> conversion, <span class="hljs-built_in">expr</span>? format_spec)
         | <span class="hljs-type">JoinedStr</span>(<span class="hljs-built_in">expr</span>* values)

         -- the following expression can appear <span class="hljs-keyword">in</span> assignment context
         | <span class="hljs-type">Attribute</span>(<span class="hljs-built_in">expr</span> value, identifier attr, expr_context ctx)
         | <span class="hljs-type">Subscript</span>(<span class="hljs-built_in">expr</span> value, <span class="hljs-built_in">expr</span> slice, expr_context ctx)
         | <span class="hljs-type">Name</span>(identifier id, expr_context ctx)
         | <span class="hljs-type">Tuple</span>(<span class="hljs-built_in">expr</span>* elts, expr_context ctx)

         -- can appear only <span class="hljs-keyword">in</span> <span class="hljs-type">Subscript</span>
         | <span class="hljs-type">Slice</span>(<span class="hljs-built_in">expr</span>? lower, <span class="hljs-built_in">expr</span>? upper, <span class="hljs-built_in">expr</span>? step)

          -- col_offset <span class="hljs-keyword">is</span> the byte offset <span class="hljs-keyword">in</span> the utf8 <span class="hljs-built_in">string</span> the parser uses
          attributes (<span class="hljs-built_in">int</span> lineno, <span class="hljs-built_in">int</span> col_offset, <span class="hljs-built_in">int</span>? end_lineno, <span class="hljs-built_in">int</span>? end_col_offset)

    expr_context = <span class="hljs-type">Load</span> | <span class="hljs-type">Store</span> | <span class="hljs-type">Del</span>

    cmpop = <span class="hljs-type">Eq</span> | <span class="hljs-type">NotEq</span> | <span class="hljs-type">Lt</span> | <span class="hljs-type">LtE</span> | <span class="hljs-type">Gt</span> | <span class="hljs-type">GtE</span> | <span class="hljs-type">Is</span> | <span class="hljs-type">IsNot</span> | <span class="hljs-type">In</span> | <span class="hljs-type">NotIn</span>

    comprehension = (<span class="hljs-built_in">expr</span> target, <span class="hljs-built_in">expr</span> iter, <span class="hljs-built_in">expr</span>* ifs, <span class="hljs-built_in">int</span> is_async)

    excepthandler = <span class="hljs-type">ExceptHandler</span>(<span class="hljs-built_in">expr</span>? <span class="hljs-keyword">type</span>, identifier? name, <span class="hljs-built_in">stmt</span>* body)
                    attributes (<span class="hljs-built_in">int</span> lineno, <span class="hljs-built_in">int</span> col_offset, <span class="hljs-built_in">int</span>? end_lineno, <span class="hljs-built_in">int</span>? end_col_offset)

    arguments = (arg* posonlyargs, arg* args, arg? vararg, arg* kwonlyargs,
                 <span class="hljs-built_in">expr</span>* kw_defaults, arg? kwarg, <span class="hljs-built_in">expr</span>* defaults)

    arg = (identifier arg, <span class="hljs-built_in">expr</span>? annotation, <span class="hljs-built_in">string</span>? type_comment)
           attributes (<span class="hljs-built_in">int</span> lineno, <span class="hljs-built_in">int</span> col_offset, <span class="hljs-built_in">int</span>? end_lineno, <span class="hljs-built_in">int</span>? end_col_offset)

    -- keyword arguments supplied to call (<span class="hljs-type">NULL</span> identifier <span class="hljs-keyword">for</span> **kwargs)
    keyword = (identifier? arg, <span class="hljs-built_in">expr</span> value)
               attributes (<span class="hljs-built_in">int</span> lineno, <span class="hljs-built_in">int</span> col_offset, <span class="hljs-built_in">int</span>? end_lineno, <span class="hljs-built_in">int</span>? end_col_offset)

    -- <span class="hljs-keyword">import</span> name <span class="hljs-keyword">with</span> optional '<span class="hljs-keyword">as</span>' alias.
    alias = (identifier name, identifier? asname)
             attributes (<span class="hljs-built_in">int</span> lineno, <span class="hljs-built_in">int</span> col_offset, <span class="hljs-built_in">int</span>? end_lineno, <span class="hljs-built_in">int</span>? end_col_offset)

    withitem = (<span class="hljs-built_in">expr</span> context_expr, <span class="hljs-built_in">expr</span>? optional_vars)

    match_case = (pattern pattern, <span class="hljs-built_in">expr</span>? guard, <span class="hljs-built_in">stmt</span>* body)

    pattern = <span class="hljs-type">MatchValue</span>(<span class="hljs-built_in">expr</span> value)
            | <span class="hljs-type">MatchSingleton</span>(constant value)
            | <span class="hljs-type">MatchSequence</span>(pattern* patterns)
            | <span class="hljs-type">MatchMapping</span>(<span class="hljs-built_in">expr</span>* keys, pattern* patterns, identifier? rest)
            | <span class="hljs-type">MatchClass</span>(<span class="hljs-built_in">expr</span> cls, pattern* patterns, identifier* kwd_attrs, pattern* kwd_patterns)

            | <span class="hljs-type">MatchStar</span>(identifier? name)
            -- <span class="hljs-type">The</span> optional <span class="hljs-string">"rest"</span> <span class="hljs-type">MatchMapping</span> parameter handles capturing extra mapping keys

            | <span class="hljs-type">MatchAs</span>(pattern? pattern, identifier? name)
            | <span class="hljs-type">MatchOr</span>(pattern* patterns)

             attributes (<span class="hljs-built_in">int</span> lineno, <span class="hljs-built_in">int</span> col_offset, <span class="hljs-built_in">int</span> end_lineno, <span class="hljs-built_in">int</span> end_col_offset)

    type_ignore = <span class="hljs-type">TypeIgnore</span>(<span class="hljs-built_in">int</span> lineno, <span class="hljs-built_in">string</span> tag)

    type_param = <span class="hljs-type">TypeVar</span>(identifier name, <span class="hljs-built_in">expr</span>? bound)
               | <span class="hljs-type">ParamSpec</span>(identifier name)
               | <span class="hljs-type">TypeVarTuple</span>(identifier name)
               attributes (<span class="hljs-built_in">int</span> lineno, <span class="hljs-built_in">int</span> col_offset, <span class="hljs-built_in">int</span> end_lineno, <span class="hljs-built_in">int</span> end_col_offset)
}</pre>

Implemented Components are removed
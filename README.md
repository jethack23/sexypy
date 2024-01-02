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
<pre class="nimrod hljs" style="text-align: start;" data-mce-style="background-color: #f8f8f8; color: #000000; text-align: start;" contenteditable="false" data-mce-selected="1">-- <span class="hljs-type">ASDL</span>'s <span class="hljs-number">4</span> builtin types are:
-- identifier, <span class="hljs-built_in">int</span>, <span class="hljs-built_in">string</span>, constant

module <span class="hljs-type">Python</span>
{
    <span class="hljs-keyword">mod</span> = <span class="hljs-type">Module</span>(<span class="hljs-built_in">stmt</span>* body, type_ignore* type_ignores)
        | <span class="hljs-type">Interactive</span>(<span class="hljs-built_in">stmt</span>* body)
        | <span class="hljs-type">Expression</span>(<span class="hljs-built_in">expr</span> body)
        | <span class="hljs-type">FunctionType</span>(<span class="hljs-built_in">expr</span>* argtypes, <span class="hljs-built_in">expr</span> returns)

    <span class="hljs-built_in">stmt</span> = <span class="hljs-type">AsyncFunctionDef</span>(identifier name, arguments args,
                             <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">expr</span>* decorator_list, <span class="hljs-built_in">expr</span>? returns,
                             <span class="hljs-built_in">string</span>? type_comment)

          -- 'simple' indicates that we annotate simple name <span class="hljs-keyword">without</span> parens
          | <span class="hljs-type">AnnAssign</span>(<span class="hljs-built_in">expr</span> target, <span class="hljs-built_in">expr</span> annotation, <span class="hljs-built_in">expr</span>? value, <span class="hljs-built_in">int</span> simple)

          -- use 'orelse' because <span class="hljs-keyword">else</span> <span class="hljs-keyword">is</span> a keyword <span class="hljs-keyword">in</span> target languages
          | <span class="hljs-type">AsyncFor</span>(<span class="hljs-built_in">expr</span> target, <span class="hljs-built_in">expr</span> iter, <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">stmt</span>* orelse, <span class="hljs-built_in">string</span>? type_comment)
          | <span class="hljs-type">With</span>(withitem* items, <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">string</span>? type_comment)
          | <span class="hljs-type">AsyncWith</span>(withitem* items, <span class="hljs-built_in">stmt</span>* body, <span class="hljs-built_in">string</span>? type_comment)

          | <span class="hljs-type">Match</span>(<span class="hljs-built_in">expr</span> subject, match_case* cases)

          | <span class="hljs-type">Assert</span>(<span class="hljs-built_in">expr</span> test, <span class="hljs-built_in">expr</span>? msg)

          -- col_offset <span class="hljs-keyword">is</span> the byte offset <span class="hljs-keyword">in</span> the utf8 <span class="hljs-built_in">string</span> the parser uses
          attributes (<span class="hljs-built_in">int</span> lineno, <span class="hljs-built_in">int</span> col_offset, <span class="hljs-built_in">int</span>? end_lineno, <span class="hljs-built_in">int</span>? end_col_offset)

    <span class="hljs-built_in">expr</span> = <span class="hljs-type">ListComp</span>(<span class="hljs-built_in">expr</span> elt, comprehension* generators)
         | <span class="hljs-type">SetComp</span>(<span class="hljs-built_in">expr</span> elt, comprehension* generators)
         | <span class="hljs-type">DictComp</span>(<span class="hljs-built_in">expr</span> key, <span class="hljs-built_in">expr</span> value, comprehension* generators)
         | <span class="hljs-type">GeneratorExp</span>(<span class="hljs-built_in">expr</span> elt, comprehension* generators)
         -- the grammar constrains where <span class="hljs-keyword">yield</span> expressions can occur
         | <span class="hljs-type">Await</span>(<span class="hljs-built_in">expr</span> value)
         | <span class="hljs-type">Yield</span>(<span class="hljs-built_in">expr</span>? value)
         | <span class="hljs-type">YieldFrom</span>(<span class="hljs-built_in">expr</span> value)
         | <span class="hljs-type">FormattedValue</span>(<span class="hljs-built_in">expr</span> value, <span class="hljs-built_in">int</span> conversion, <span class="hljs-built_in">expr</span>? format_spec)
         | <span class="hljs-type">JoinedStr</span>(<span class="hljs-built_in">expr</span>* values)

          -- col_offset <span class="hljs-keyword">is</span> the byte offset <span class="hljs-keyword">in</span> the utf8 <span class="hljs-built_in">string</span> the parser uses
          attributes (<span class="hljs-built_in">int</span> lineno, <span class="hljs-built_in">int</span> col_offset, <span class="hljs-built_in">int</span>? end_lineno, <span class="hljs-built_in">int</span>? end_col_offset)



    comprehension = (<span class="hljs-built_in">expr</span> target, <span class="hljs-built_in">expr</span> iter, <span class="hljs-built_in">expr</span>* ifs, <span class="hljs-built_in">int</span> is_async)

    excepthandler = <span class="hljs-type">ExceptHandler</span>(<span class="hljs-built_in">expr</span>? <span class="hljs-keyword">type</span>, identifier? name, <span class="hljs-built_in">stmt</span>* body)
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

}</pre>

Implemented Components are removed   
- type_comment never considered. Later, it should be covered
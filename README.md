# SexyPy : the Most Nerdy Python Ever!
SexyPy stands for **S-ex**_pression-ish(_**y**_)_ **Py**_thon_.   
Highly inspired by Clojure and Hy.   
Once I loved to use Hy when I need to use python. But as I started to learn Clojure, similarity between two languages confused me. I want a language more straightforward to being python but in S-expression so that I can exploit structural editing and metaprogramming by macro. Thus I decided to start this project.

# Run from source
```bash
spy {filename}.sy
```

# Run REPL
```bash
spy
#or
spy -t #if you want to print python translation.
```

# Run translation
```bash
s2py {filename}.sy
```
It just displays translation. (don't run it)

# Run Tests
```bash
# in project root directory
python -m unittest
#or
hy -m unittest
```


# AST todo
- type_comment never considered. Later, it should be covered
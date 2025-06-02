# Why Sxpy?
## Just a new syntax for Python
Sxpy is not a new language. It is just a new syntax for Python.
You can just think in Python, write in Sxpy.
You'll experience less breaking changes.
It also provides some pythonic syntax such as "list comprehensions".

## Python Interop: 100% Compatible with Vanila Python
Sxpy is 100% compatible with Python.
You can use any Python libraries and modules in Sxpy.
You can also use Sxpy modules in Python.
### Interop example
#### Import numpy in Sxpy
```python
(import numpy as np)
```
#### Import Sxpy Code in Python
When you have function `bar` in `foo.sy` file
```python
import sxpy # it makes python interop available
from foo import bar
foo()
```


## Macro system
Sxpy has a Lisp-like macro system. This can be achieved by its s-expression-like syntax.

I recommend reading Paul Graham’s article [Beating the Average](https://paulgraham.com/avg.html), which illustrates why macro systems are valuable.
### Macro example
`do-while` macro
```python
; do-while macro example
(defmacro do-while [pred *body]
  (return `(do
             ~@body
             (while ~pred
               ~@body))))

(do-while False (print "Does it really happen?"))
```
Translated into Python:
```python
print('Does it really happen?')
while False:
    print('Does it really happen?')
```

## Structural editing
Check out the [Structural Editing](https://clojure.org/guides/structural_editing) section in Clojure documentation.

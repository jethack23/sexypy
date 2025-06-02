# SexyPy : the Geekiest Python Ever!
This documentation stands for version **{{ version }}**

## What is SexyPy?
SexyPy stands for **S-ex**_pression-ish(_**y**_)_ **Py**_thon_.   
I'm gonna use the abbreviation **Sxpy** throughout this documentation.   
   
Sxpy is highly inspired by [Clojure](https://clojure.org/) and [Hy](https://hylang.org/).   
It provides a new s-expression-like syntax for Python. (Thus, macro system also)   
I started this project because I experienced some problems with Hy.

## Problems I had while using Hy
- The philosophy of Hy is "a Lisp dialect that's embedded in Python".
    - As a standalone language, Hy evolves fast. And it is hard to keep track of the breaking changes in Hy.
- It resembles Clojure too much.
    - As I started to learn Clojure, similarity between two languages confused me.

## Why Sxpy?
### Just a new syntax for Python
Sxpy is not a new language. It is just a new syntax for Python.   
You'll experience less breaking changes and you can just think in Python, write in Sxpy.   
It also provides some pythonic syntax such as "list comprehensions".
### Macro system
Sxpy has a Lisp-like macro system.   
This can be achieved by its s-expression-like syntax.   
I recommend reading Paul Graham’s article [Beating the Average](https://paulgraham.com/avg.html), which illustrates why macro systems are valuable.
#### Macro example
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

### Structural editing
Check out the [Structural Editing](https://clojure.org/guides/structural_editing) section in Clojure documentation.

# Expressions
## Operators
### Boolean Operators
Sxpy version
```python
(and expr1 expr2 ...)
```
Python version
```python
expr1 and expr2 and ...
```
### Binary Operators
Sxpy version
```python
(+ n1 n2 ...)
```
Python version
```python
n1 + n2 + ...
```
### Unary Operators
Sxpy version
```python
(- n)
```
Python version
```python
-n
```
### Comparison Operators
#### `==`
Sxpy version
```python
(== expr1 expr2 expr3 ...)
```
Python version
```python
expr1 == expr2 == expr3 == ...
```
#### `>`
Python version
```python
(> expr1 expr2 expr3 ...)
```
Sxpy version
```python
expr1 > expr2 > expr3 > ...
```

## `:=`
Sxpy version
```python
(:= name value)
```
Python version
```python
(name := value)
```

## `labmda`
Sxpy version
```python
(lambda [arg1 arg2 ...] body)
# or syntactic sugar fn
(fn [arg1 arg2 ...] body)
```
Python version
```python
lambda arg1, arg2, ...: body
```
## `if` expression
Sxpy version
```python
(ife test then other)
```
Python version
```python
then if test else other
```
## Collection Literals
### List
Sxpy version
```python
[item1 item2 ...]
```
Python version
```python
[item1, item2, ...]
```
### Dictionary
Sxpy version
```python
{key1 value1 key2 value2 ...}
```
Python version
```python
{key1: value1, key2: value2, ...}
```
### Set
Sxpy version
```python
{, item1 item2 ...}
```
Python version
```python
{item1, item2, ...}
```
### Tuple
Sxpy version
```python
(, item1 item2 ...)
```
Python version
```python
(item1, item2, ...)
```
## Comprehensions
### List Comprehension
Sxpy version
```python
[(* 2 x) for x in (range 10) if (== (% x 2) 0)]
```
Python version
```python
[2 * x for x in range(10) if x % 2 == 0]
```
### Dictionary Comprehension
Sxpy version
```python
{(* 2 x) (* 3 x) for x in (range 10) if (== (% x 2) 0)}
```
Python version
```python
{2 * x: 3 * x for x in range(10) if x % 2 == 0}
```
### Set Comprehension
Sxpy version
```python
{, (* 2 x) for x in (range 10) if (== (% x 2) 0)}
```
Python version
```python
{2 * x for x in range(10) if x % 2 == 0}
```
### Generator Expression
Sxpy version
```python
((* 2 x) for x in (range 10) if (== (% x 2) 0))
```
Python version
```python
(2 * x for x in range(10) if x % 2 == 0)
```

## `await`
Sxpy version
```python
(await expr)
```
Python version
```python
await expr
```
## `yield`
Sxpy version
```python
(yield expr)
```
Python version
```python
yield expr
```
## `yield from`
Sxpy version
```python
(yield-from expr)
```
Python version
```python
yield from expr
```
## Function Call
Sxpy version
```python
(func-name arg1 arg2 *args :kwarg1 value1 :kwarg2 value2 **kwargs)
```
Python version
```python
func_name(arg1, arg2, *args, kwarg1=value1, kwarg2=value2, **kwargs)
```
## Formatted String Literals
Sxpy version
```python
(= name "World")
f"Hello, {(* 2 name)}!"
```
Python version
```python
name = "World"
f"Hello, {2 * name}!"
```

## Attribute
Sxpy version
```python
(. obj attr)
```
Python version
```python
obj.attr
```
## Method Call
Sxpy version
```python
(.method-name obj arg1 arg2 *args :kwarg1 value1 :kwarg2 value2 **kwargs)
```
Python version
```python
obj.method_name(arg1, arg2, *args, kwarg1=value1, kwarg2=value2, **kwargs)
```
## Subscription
### Simple Subscription
Sxpy version
```python
(sub obj i1 i2)
```
Python version
```python
obj[i1][i2]
```
### Tuple Subscription
Sxpy version
```python
(sub obj (, i1 i2 ...))
```
Python version
```python
obj[i1, i2, ...]
```
## Slice
### Slice Subscription
Sxpy version
```python
(sub obj [: start stop step])
```
Python version
```python
obj[start:stop:step]
```
### Slice with Emptiness
Sxpy version
```python
(sub obj [: start])
(sub obj [: _ stop])
(sub obj [: start _ step])
```
Python version
```python
obj[start:]
obj[:stop]
obj[start::step]
```
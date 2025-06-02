## Function Definition
Python version
```python
@decorator1
@decorator2
def function_name(arg1, arg2, *args, kwarg1=value1, kwarg2=value2, **kwargs):
    """docstring"""
    body
```
Sxpy version
```python
(deco [decorator1
       decorator2]
  (def function-name [arg1 arg2 *args :kwarg1 value1 :kwarg2 value2 **kwargs]
    "docstring"
    body))
```
## Async Function Definition
Use `async-def` instead of `def`.
## REPL
```shell
spy
#or
spy -t #if you want to print python translation.
```
## Run from source
```shell
spy {filename}.sy
```
## Run translation
```shell
s2py {filename}.sy
```
It just displays translation. (don't run it)
## Run Tests (for development)
```shell
# in project root directory
python -m unittest
#or
spy -m unittest
```
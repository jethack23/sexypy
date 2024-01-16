import ast
import argparse
import io
import os
import os.path as osp
import runpy
import subprocess
import black
from sxpy.parser import parse
from sxpy.macro import macroexpand_then_compile


def ast_to_python(st):
    return str(ast.unparse(st))


def src_to_python(src):
    return "\n".join(map(ast_to_python, macroexpand_then_compile(parse(src))))


argparser = argparse.ArgumentParser()
argparser.add_argument("filename", nargs="?", default="")
argparser.add_argument(
    "-t",
    "--translate",
    dest="translate",
    action="store_const",
    const=True,
    default=False,
)
argparser.add_argument("-m", dest="module_name", action="store")


def transcompile():
    args = argparser.parse_args()
    file = osp.join(os.getcwd(), args.filename)
    _hy_anon_var_1 = None
    with open(file, "r") as f:
        org = f.read()
        blacked = black.format_str(src_to_python(org), mode=black.FileMode()).rstrip(
            "\n"
        )
        _hy_anon_var_1 = None
    return print(blacked)


def _is_sy_file(filename):
    return osp.isfile(filename) and osp.splitext(filename)[1] in [".sy"]


def inject_runpy():
    _org_get_code_from_file = runpy._get_code_from_file

    def _get_sy_code_from_file(run_name, fname):
        from pkgutil import read_code

        decoded_path = osp.abspath(os.fsdecode(fname))
        _hy_anon_var_2 = None
        with io.open_code(decoded_path) as f:
            code = read_code(f)
            _hy_anon_var_2 = None
        if code is None:
            if _is_sy_file(fname):
                _hy_anon_var_3 = None
                with open(decoded_path, "rb") as f:
                    _hy_anon_var_3 = compile(
                        ast.Module(
                            macroexpand_then_compile(parse(f.read().decode("utf-8"))),
                            type_ignores=[],
                        ),
                        fname,
                        "exec",
                    )
                code = _hy_anon_var_3
            else:
                code = _org_get_code_from_file(run_name, fname)[0]
            _hy_anon_var_5 = None
        else:
            _hy_anon_var_5 = None
        return [code, fname]

    runpy._get_code_from_file = _get_sy_code_from_file


def repl(translate):
    while True:
        line = input("repl > \n")
        src = ""
        while line != "":
            src += "\n" + line
            line = input("")
        parsed = parse(src)
        stl = macroexpand_then_compile(parsed)
        if translate:
            print("python translation")
            print("\n".join(list(map(ast_to_python, stl))))
            _hy_anon_var_6 = print("")
        else:
            _hy_anon_var_6 = None
        print("result")
        for st in stl:
            eval(compile(ast.Interactive(body=[st]), "", "single"), globals())
        print("\n")


def run():
    args = argparser.parse_args()
    runpy.run_path(
        args.filename, run_name="__main__"
    ) if args.filename else runpy.run_module(
        args.module_name, run_name="__main__", alter_sys=True
    ) if args.module_name else repl(
        args.translate
    ) if True else None
    return None

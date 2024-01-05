(import ast)


(setv unaryop-dict {"+" ast.UAdd
                    "-" ast.USub
                    "not" ast.Not
                    "~" ast.Invert}

      binop-dict {"+" ast.Add
                  "-" ast.Sub
                  "*" ast.Mult
                  "/" ast.Div
                  "//" ast.FloorDiv
                  "%" ast.Mod
                  "**" ast.Pow
                  "<<" ast.LShift
                  ">>" ast.RShift
                  "|" ast.BitOr
                  "^" ast.BitXor
                  "&" ast.BitAnd
                  "@" ast.MatMult}

      augassignop-dict (dfor [k v] (binop-dict.items) (+ k "=") v)

      boolop-dict {"and" ast.And
                   "or" ast.Or}

      compare-dict {"==" ast.Eq
                    "!=" ast.NotEq
                    "<" ast.Lt
                    "<=" ast.LtE
                    ">" ast.Gt
                    ">=" ast.GtE
                    "is" ast.Is
                    "is-not" ast.IsNot
                    "in" ast.In
                    "not-in" ast.NotIn}
      )

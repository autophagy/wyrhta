module Views.String exposing (capitalize)


capitalize : String -> String
capitalize word =
    String.uncons word
        |> Maybe.map (\( head, tail ) -> String.cons (Char.toUpper head) tail)
        |> Maybe.withDefault ""

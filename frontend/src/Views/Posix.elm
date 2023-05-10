module Views.Posix exposing (comparePosix, posixToString)

import Time exposing (Month(..), Posix, posixToMillis, toDay, toMonth, toYear, utc)


monthToString : Month -> String
monthToString month =
    case month of
        Jan ->
            "01"

        Feb ->
            "02"

        Mar ->
            "03"

        Apr ->
            "04"

        May ->
            "05"

        Jun ->
            "06"

        Jul ->
            "07"

        Aug ->
            "08"

        Sep ->
            "09"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"


posixToString : Posix -> String
posixToString p =
    String.join "." [ String.fromInt <| toYear utc p, monthToString <| toMonth utc p, String.pad 2 '0' <| String.fromInt <| toDay utc p ]


comparePosix : Posix -> Posix -> Order
comparePosix a b =
    compare (posixToMillis a) (posixToMillis b)

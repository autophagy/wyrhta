module Views.Footer exposing (footer)

import Html exposing (Html)
import Html.Attributes as A


footer : Html msg
footer =
    Html.footer [ A.class "container" ]
        [ Html.a [ A.href "/" ] [ Html.text "Home" ]
        , Html.a [ A.href "/about" ] [ Html.text "About" ]
        ]

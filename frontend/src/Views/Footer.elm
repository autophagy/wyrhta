module Views.Footer exposing (footer)

import Html exposing (Html)
import Html.Attributes as A
import Route.Path


footer : Html msg
footer =
    Html.footer [ A.class "container" ]
        [ Html.a [ Route.Path.href Route.Path.Home_ ] [ Html.text "Home" ]
        , Html.a [ Route.Path.href Route.Path.About ] [ Html.text "About" ]
        ]

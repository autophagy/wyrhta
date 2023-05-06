module Views.LoadingPage exposing (PageState(..), viewLoadingPage)

import Html exposing (Html)
import Html.Attributes exposing (class)


type PageState
    = Loading
    | Loaded
    | Error


viewLoadingPage : (a -> PageState) -> a -> List (Html msg) -> Html msg
viewLoadingPage f a e =
    case f a of
        Loaded ->
            Html.div [ class "loaded" ] e

        Loading ->
            Html.div [ class "loading" ] []

        Error ->
            Html.div [ class "error" ] [ Html.text ":(" ]

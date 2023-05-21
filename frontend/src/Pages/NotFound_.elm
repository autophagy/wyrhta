module Pages.NotFound_ exposing (page)

import Html
import Html.Attributes as A
import View exposing (View)


page : View msg
page =
    { title = Just "Not Found"
    , body = [ Html.div [ A.class "not-found-container" ] [ Html.img [ A.src "/img/logo.svg" ] [], Html.text "Not Found" ] ]
    }

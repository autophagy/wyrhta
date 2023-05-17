module Pages.NotFound_ exposing (page)

import View exposing (View)
import Html
import Html.Attributes as A


page : View msg
page =
    { title = "Not Found"
    , body = [ Html.div [ A.class "not-found-container" ] [ Html.img [ A.src "/img/logo.svg" ] [], Html.text "Not Found" ] ]}

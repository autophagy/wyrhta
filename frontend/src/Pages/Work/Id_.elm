module Pages.Work.Id_ exposing (page)

import Html exposing (Html)
import View exposing (View)


page : { id : String } -> View msg
page params =
    { title = "Pages.Work.Id_"
    , body = [ Html.text ("/work/" ++ params.id) ]
    }

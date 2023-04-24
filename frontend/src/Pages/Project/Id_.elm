module Pages.Project.Id_ exposing (page)

import Html exposing (Html)
import View exposing (View)


page : { id : String } -> View msg
page params =
    { title = "Pages.Project.Id_"
    , body = [ Html.text ("/project/" ++ params.id) ]
    }

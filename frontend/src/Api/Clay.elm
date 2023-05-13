module Api.Clay exposing (Clay, clayDecoder, getClays)

import Api exposing (Route(..))
import Http
import Json.Decode exposing (Decoder, field, float, int, map4, maybe, string)


type alias Clay =
    { id : Int
    , name : String
    , description : Maybe String
    , shrinkage : Float
    }


getClays : { onResponse : Result Http.Error (List Clay) -> msg } -> Cmd msg
getClays options =
    Api.get
        { route = [ Clays ]
        , expect = Http.expectJson options.onResponse (Json.Decode.list clayDecoder)
        }


clayDecoder : Decoder Clay
clayDecoder =
    map4 Clay
        (field "id" int)
        (field "name" string)
        (field "description" (maybe string))
        (field "shrinkage" float)

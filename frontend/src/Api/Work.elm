module Api.Work exposing (Work, getWork)

import Api exposing (ApiResource, apiResourceDecoder)
import Api.State exposing (State, stateDecoder)
import Http
import Json.Decode exposing (Decoder, field, int, map7, maybe, string)
import Json.Decode.Extra exposing (datetime)
import Time exposing (Posix)


type alias Work =
    { id : Int
    , project : ApiResource
    , name : String
    , notes : Maybe String
    , current_state : State
    , glaze_description : Maybe String
    , created_at : Posix
    }


workDecoder : Decoder Work
workDecoder =
    map7 Work
        (field "id" int)
        (field "project" apiResourceDecoder)
        (field "name" string)
        (field "notes" (maybe string))
        (field "current_state" stateDecoder)
        (field "glaze_description" (maybe string))
        (field "created_at" datetime)


getWork : Int -> { onResponse : Result Http.Error Work -> msg } -> Cmd msg
getWork id options =
    Http.get
        { url = "http://localhost:8000/works/" ++ String.fromInt id
        , expect = Http.expectJson options.onResponse workDecoder
        }

module Api.Work exposing (Work, getWork, getWorkEvents)

import Api exposing (ApiResource, andThenDecode, apiResourceDecoder)
import Api.Event exposing (Event, eventsDecoder)
import Api.State exposing (State, stateDecoder)
import Http
import Json.Decode exposing (Decoder, field, float, int, map2, map4, maybe, string, succeed)
import Json.Decode.Extra exposing (datetime)
import Time exposing (Posix)


type alias CurrentState =
    { state : State
    , transitioned_at : Posix
    }


type alias Images =
    { header : Maybe String
    , thumbnail : Maybe String
    }


type alias Clay =
    { id : Int
    , name : String
    , description : Maybe String
    , shrinkage : Float
    }


type alias Work =
    { id : Int
    , project : ApiResource
    , name : String
    , notes : Maybe String
    , clay : Clay
    , current_state : CurrentState
    , glaze_description : Maybe String
    , images : Images
    , created_at : Posix
    }


currentStateDecoder : Decoder CurrentState
currentStateDecoder =
    map2 CurrentState
        (field "state" stateDecoder)
        (field "transitioned_at" datetime)


imagesDecoder : Decoder Images
imagesDecoder =
    map2 Images
        (field "header" (maybe string))
        (field "thumbnail" (maybe string))


clayDecoder : Decoder Clay
clayDecoder =
    map4 Clay
        (field "id" int)
        (field "name" string)
        (field "description" (maybe string))
        (field "shrinkage" float)


workDecoder : Decoder Work
workDecoder =
    succeed Work
        |> andThenDecode (field "id" int)
        |> andThenDecode (field "project" apiResourceDecoder)
        |> andThenDecode (field "name" string)
        |> andThenDecode (field "notes" (maybe string))
        |> andThenDecode (field "clay" clayDecoder)
        |> andThenDecode (field "current_state" currentStateDecoder)
        |> andThenDecode (field "glaze_description" (maybe string))
        |> andThenDecode (field "images" imagesDecoder)
        |> andThenDecode (field "created_at" datetime)


getWork : Int -> { onResponse : Result Http.Error Work -> msg } -> Cmd msg
getWork id options =
    Http.get
        { url = "http://localhost:8000/works/" ++ String.fromInt id
        , expect = Http.expectJson options.onResponse workDecoder
        }


getWorkEvents : Int -> { onResponse : Result Http.Error (List Event) -> msg } -> Cmd msg
getWorkEvents id options =
    Http.get
        { url = "http://localhost:8000/works/" ++ String.fromInt id ++ "/events"
        , expect = Http.expectJson options.onResponse eventsDecoder
        }

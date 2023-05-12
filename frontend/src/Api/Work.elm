module Api.Work exposing (UpdateWork, Work, deleteWork, getWork, getWorkEvents, getWorks, postWork, putWork, workDecoder)

import Api exposing (ApiResource, andThenDecode, apiResourceDecoder)
import Api.Clay exposing (Clay, clayDecoder)
import Api.Event exposing (Event, eventsDecoder)
import Api.State exposing (State, stateDecoder)
import Http
import Json.Decode exposing (Decoder, field, int, list, map2, maybe, string, succeed)
import Json.Decode.Extra exposing (datetime)
import Json.Encode as Encode
import Json.Encode.Extra as Encode
import Time exposing (Posix)


type alias CurrentState =
    { state : State
    , transitioned_at : Posix
    }


type alias Images =
    { header : Maybe String
    , thumbnail : Maybe String
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


getWorks : { onResponse : Result Http.Error (List Work) -> msg } -> Cmd msg
getWorks options =
    Http.get
        { url = "http://localhost:8000/works"
        , expect = Http.expectJson options.onResponse (list workDecoder)
        }


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



-- PUT


type alias UpdateWork =
    { project_id : Int
    , name : String
    , notes : Maybe String
    , clay_id : Int
    , glaze_description : Maybe String
    , thumbnail : Maybe String
    , header : Maybe String
    }


workEncoder : UpdateWork -> Encode.Value
workEncoder work =
    Encode.object
        [ ( "project_id", Encode.int work.project_id )
        , ( "name", Encode.string work.name )
        , ( "notes", Encode.maybe Encode.string work.notes )
        , ( "clay_id", Encode.int work.clay_id )
        , ( "glaze_description", Encode.maybe Encode.string work.glaze_description )
        , ( "thumbnail", Encode.maybe Encode.string work.thumbnail )
        , ( "header", Encode.maybe Encode.string work.header )
        ]


putWork : Int -> UpdateWork -> { onResponse : Result Http.Error () -> msg } -> Cmd msg
putWork id project options =
    Http.request
        { method = "PUT"
        , headers = []
        , url = "http://localhost:8000/works/" ++ String.fromInt id
        , body = Http.jsonBody <| workEncoder project
        , expect = Http.expectWhatever options.onResponse
        , timeout = Nothing
        , tracker = Nothing
        }


postWork : UpdateWork -> { onResponse : Result Http.Error Int -> msg } -> Cmd msg
postWork project options =
    Http.request
        { method = "POST"
        , headers = []
        , url = "http://localhost:8000/works"
        , body = Http.jsonBody <| workEncoder project
        , expect = Http.expectJson options.onResponse int
        , timeout = Nothing
        , tracker = Nothing
        }


deleteWork : Int -> { onResponse : Result Http.Error () -> msg } -> Cmd msg
deleteWork id options =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = "http://localhost:8000/works/" ++ String.fromInt id
        , body = Http.emptyBody
        , expect = Http.expectWhatever options.onResponse
        , timeout = Nothing
        , tracker = Nothing
        }

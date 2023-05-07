module Api.Project exposing (..)

import Api.Work exposing (Work, workDecoder)
import Http
import Json.Decode exposing (Decoder, field, int, list, map2, map5, maybe, string)
import Json.Decode.Extra exposing (datetime)
import Json.Encode as Encode
import Json.Encode.Extra as Encode
import Time exposing (Posix)



-- GET


type alias Images =
    { header : Maybe String
    , thumbnail : Maybe String
    }


type alias Project =
    { id : Int
    , name : String
    , description : Maybe String
    , images : Images
    , created_at : Posix
    }


projectsDecoder : Decoder (List Project)
projectsDecoder =
    Json.Decode.list projectDecoder


projectDecoder : Decoder Project
projectDecoder =
    map5 Project
        (field "id" int)
        (field "name" string)
        (field "description" (maybe string))
        (field "images" imagesDecoder)
        (field "created_at" datetime)


imagesDecoder : Decoder Images
imagesDecoder =
    map2 Images
        (field "header" (maybe string))
        (field "thumbnail" (maybe string))


getProjects : { onResponse : Result Http.Error (List Project) -> msg } -> Cmd msg
getProjects options =
    Http.get
        { url = "http://localhost:8000/projects"
        , expect = Http.expectJson options.onResponse projectsDecoder
        }


getProject : Int -> { onResponse : Result Http.Error Project -> msg } -> Cmd msg
getProject id options =
    Http.get
        { url = "http://localhost:8000/projects/" ++ String.fromInt id
        , expect = Http.expectJson options.onResponse projectDecoder
        }


getProjectWorks : Int -> { onResponse : Result Http.Error (List Work) -> msg } -> Cmd msg
getProjectWorks id options =
    Http.get
        { url = "http://localhost:8000/projects/" ++ String.fromInt id ++ "/works"
        , expect = Http.expectJson options.onResponse (list workDecoder)
        }



-- PUT


type alias UpdateProject =
    { name : String
    , description : Maybe String
    }


projectEncoder : UpdateProject -> Encode.Value
projectEncoder project =
    Encode.object
        [ ( "name", Encode.string project.name )
        , ( "description", Encode.maybe Encode.string project.description )
        ]


putProject : Int -> UpdateProject -> { onResponse : Result Http.Error () -> msg } -> Cmd msg
putProject id project options =
    Http.request
        { method = "PUT"
        , headers = []
        , url = " http://localhost:8000/projects/" ++ String.fromInt id
        , body = Http.jsonBody <| projectEncoder project
        , expect = Http.expectWhatever options.onResponse
        , timeout = Nothing
        , tracker = Nothing
        }

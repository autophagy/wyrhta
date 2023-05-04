module Api.Project exposing (Project, getProject, getProjects)

import Http
import Json.Decode exposing (Decoder, field, int, map4, maybe, string)
import Json.Decode.Extra exposing (datetime)
import Time exposing (Posix)


type alias Project =
    { id : Int
    , name : String
    , description : Maybe String
    , created_at : Posix
    }


projectsDecoder : Decoder (List Project)
projectsDecoder =
    Json.Decode.list projectDecoder


projectDecoder : Decoder Project
projectDecoder =
    map4 Project
        (field "id" int)
        (field "name" string)
        (field "description" (maybe string))
        (field "created_at" datetime)


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

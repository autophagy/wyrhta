module Api.Project exposing (..)

import Api exposing (Route(..))
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
    Api.get
        { route = [ Projects ]
        , expect = Http.expectJson options.onResponse projectsDecoder
        }


getProject : Int -> { onResponse : Result Http.Error Project -> msg } -> Cmd msg
getProject id options =
    Api.get
        { route = [ Projects, Id id ]
        , expect = Http.expectJson options.onResponse projectDecoder
        }


getProjectWorks : Int -> { onResponse : Result Http.Error (List Work) -> msg } -> Cmd msg
getProjectWorks id options =
    Api.get
        { route = [ Projects, Id id, Works ]
        , expect = Http.expectJson options.onResponse (list workDecoder)
        }



-- PUT/POST


type alias UpdateProject =
    { name : String
    , description : Maybe String
    , thumbnail : Maybe String
    }


projectEncoder : UpdateProject -> Encode.Value
projectEncoder project =
    Encode.object
        [ ( "name", Encode.string project.name )
        , ( "description", Encode.maybe Encode.string project.description )
        , ( "thumbnail", Encode.maybe Encode.string project.thumbnail )
        ]


putProject : Int -> UpdateProject -> { onResponse : Result Http.Error () -> msg } -> Cmd msg
putProject id project options =
    Api.put
        { route = [ Projects, Id id ]
        , body = Http.jsonBody <| projectEncoder project
        , expect = Http.expectWhatever options.onResponse
        }


postProject : UpdateProject -> { onResponse : Result Http.Error Int -> msg } -> Cmd msg
postProject project options =
    Api.post
        { route = [ Projects ]
        , body = Http.jsonBody <| projectEncoder project
        , expect = Http.expectJson options.onResponse int
        }


deleteProject : Int -> { onResponse : Result Http.Error () -> msg } -> Cmd msg
deleteProject id options =
    Api.delete
        { route = [ Projects, Id id ]
        , expect = Http.expectWhatever options.onResponse
        }

module Api exposing (ApiResource, Data(..), Route(..), andThenDecode, apiResourceDecoder, delete, get, post, put, request)

import Http
import Json.Decode exposing (Decoder, andThen, field, int, map, map2, string)


type alias ApiResource =
    { id : Int
    , url : String
    }


type Route
    = Projects
    | Works
    | Events
    | EventsWithLimit Int
    | State
    | Clays
    | Upload
    | Id Int
    | Login
    | Auth


routeToString : Route -> String
routeToString route =
    case route of
        Projects ->
            "projects"

        Works ->
            "works"

        Events ->
            "events"

        EventsWithLimit limit ->
            "events?limit=" ++ String.fromInt limit

        State ->
            "state"

        Clays ->
            "clays"

        Upload ->
            "upload"

        Id i ->
            String.fromInt i

        Login ->
            "login"

        Auth ->
            "auth"


apiResourceDecoder : Decoder ApiResource
apiResourceDecoder =
    map2 ApiResource
        (field "id" int)
        (field "url" string)


type Data value
    = Loading
    | Success value
    | Failure Http.Error


andThenDecode : Decoder a -> Decoder (a -> b) -> Decoder b
andThenDecode value partial =
    andThen (\p -> map p value) partial


request :
    { method : String
    , headers : List Http.Header
    , route : List Route
    , body : Http.Body
    , expect : Http.Expect msg
    , timeout : Maybe Float
    , tracker : Maybe String
    }
    -> Cmd msg
request r =
    Http.request
        { method = r.method
        , headers = r.headers
        , url = String.join "/" <| "http://localhost:8080/api" :: List.map routeToString r.route
        , body = r.body
        , expect = r.expect
        , timeout = r.timeout
        , tracker = r.tracker
        }


get :
    { route : List Route
    , expect : Http.Expect msg
    }
    -> Cmd msg
get r =
    request
        { method = "GET"
        , headers = []
        , route = r.route
        , body = Http.emptyBody
        , expect = r.expect
        , timeout = Nothing
        , tracker = Nothing
        }


put :
    { route : List Route
    , body : Http.Body
    , expect : Http.Expect msg
    }
    -> Cmd msg
put r =
    request
        { method = "PUT"
        , headers = []
        , route = r.route
        , body = r.body
        , expect = r.expect
        , timeout = Nothing
        , tracker = Nothing
        }


post :
    { route : List Route
    , body : Http.Body
    , expect : Http.Expect msg
    }
    -> Cmd msg
post r =
    request
        { method = "POST"
        , headers = []
        , route = r.route
        , body = r.body
        , expect = r.expect
        , timeout = Nothing
        , tracker = Nothing
        }


delete :
    { route : List Route
    , expect : Http.Expect msg
    }
    -> Cmd msg
delete r =
    request
        { method = "DELETE"
        , headers = []
        , route = r.route
        , body = Http.emptyBody
        , expect = r.expect
        , timeout = Nothing
        , tracker = Nothing
        }

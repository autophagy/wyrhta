module Api.Login exposing (auth, login)

import Api exposing (Route(..))
import Http
import Json.Encode as Encode


loginEncoder : String -> Encode.Value
loginEncoder password =
    Encode.object
        [ ( "password", Encode.string password ) ]


login : String -> { onResponse : Result Http.Error () -> msg } -> Cmd msg
login password options =
    Api.post
        { route = [ Login ]
        , body = Http.jsonBody <| loginEncoder password
        , expect = Http.expectWhatever options.onResponse
        }


auth : { onResponse : Result Http.Error () -> msg } -> Cmd msg
auth options =
    Api.get
        { route = [ Auth ]
        , expect = Http.expectWhatever options.onResponse
        }

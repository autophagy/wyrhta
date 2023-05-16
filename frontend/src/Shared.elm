module Shared exposing
    ( Flags, decoder
    , Model, Msg
    , init, update, subscriptions
    )

{-|

@docs Flags, decoder
@docs Model, Msg
@docs init, update, subscriptions

-}

import Api.Login exposing (auth)
import Effect exposing (Effect)
import Json.Decode
import Route exposing (Route)
import Shared.Model
import Shared.Msg



-- FLAGS


type alias Flags =
    {}


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.succeed {}



-- INIT


type alias Model =
    Shared.Model.Model


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult route =
    ( { authenticated = Nothing }
    , Effect.auth
    )



-- UPDATE


type alias Msg =
    Shared.Msg.Msg


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update route msg model =
    case msg of
        Shared.Msg.Authenticate ->
            ( model, Effect.sendCmd <| auth { onResponse = Shared.Msg.ApiRespondedAuthenticated } )

        Shared.Msg.ApiRespondedAuthenticated (Ok ()) ->
            ( { model | authenticated = Just True }
            , Effect.none
            )

        Shared.Msg.ApiRespondedAuthenticated (Err _) ->
            ( { model | authenticated = Just False }
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions route model =
    Sub.none

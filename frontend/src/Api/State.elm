module Api.State exposing (State(..), enumState, isTerminalState, putState, stateDecoder, stateToString)

import Http
import Json.Decode exposing (Decoder, andThen, string, succeed)
import Json.Encode as Encode


type State
    = Thrown
    | Trimming
    | AwaitingBisqueFiring
    | AwaitingGlazeFiring
    | Finished
    | Recycled
    | Unknown


enumState : List State
enumState =
    [ Thrown, Trimming, AwaitingBisqueFiring, AwaitingGlazeFiring, Finished, Recycled ]


isTerminalState : State -> Bool
isTerminalState state =
    case state of
        Finished ->
            True

        Recycled ->
            True

        Unknown ->
            True

        _ ->
            False


stateToString : State -> String
stateToString s =
    case s of
        Thrown ->
            "thrown"

        Trimming ->
            "being trimmed"

        Recycled ->
            "recycled"

        AwaitingBisqueFiring ->
            "awaiting bisque firing"

        AwaitingGlazeFiring ->
            "awaiting glaze firing"

        Finished ->
            "finished"

        Unknown ->
            "unknown"


stateDecoder : Decoder State
stateDecoder =
    string
        |> andThen
            (\s ->
                case s of
                    "Thrown" ->
                        succeed Thrown

                    "Trimming" ->
                        succeed Trimming

                    "AwaitingBisqueFiring" ->
                        succeed AwaitingBisqueFiring

                    "AwaitingGlazeFiring" ->
                        succeed AwaitingGlazeFiring

                    "Finished" ->
                        succeed Finished

                    "Recycled" ->
                        succeed Recycled

                    _ ->
                        succeed Unknown
            )


stateEncoder : State -> Encode.Value
stateEncoder s =
    let
        str =
            case s of
                Thrown ->
                    "Thrown"

                Trimming ->
                    "Trimming"

                AwaitingBisqueFiring ->
                    "AwaitingBisqueFiring"

                AwaitingGlazeFiring ->
                    "AwaitingGlazeFiring"

                Finished ->
                    "Finished"

                Recycled ->
                    "Recycled"

                Unknown ->
                    "Unknown"
    in
    Encode.string str


putState : Int -> State -> { onResponse : Result Http.Error () -> msg } -> Cmd msg
putState id state options =
    Http.request
        { method = "PUT"
        , headers = []
        , url = " http://localhost:8000/works/" ++ String.fromInt id ++ "/state"
        , body = Http.jsonBody <| stateEncoder state
        , expect = Http.expectWhatever options.onResponse
        , timeout = Nothing
        , tracker = Nothing
        }

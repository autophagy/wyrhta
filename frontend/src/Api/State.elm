module Api.State exposing (State(..), isTerminalState, stateDecoder, stateToString)

import Json.Decode exposing (Decoder, andThen, string, succeed)


type State
    = Thrown
    | Trimming
    | AwaitingBisqueFiring
    | AwaitingGlazeFiring
    | Finished
    | Recycled
    | Unknown


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
            "trimming"

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

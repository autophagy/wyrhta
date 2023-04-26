module Api.State exposing (State(..), stateDecoder)

import Json.Decode exposing (Decoder, andThen, string, succeed)


type State
    = Thrown
    | Trimming
    | AwaitingBisqueFiring
    | AwaitingGlazeFiring
    | Finished
    | Recycled
    | Unknown


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

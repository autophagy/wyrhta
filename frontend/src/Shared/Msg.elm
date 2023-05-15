module Shared.Msg exposing (Msg(..))

import Http


type Msg
    = Authenticate
    | ApiRespondedAuthenticated (Result Http.Error ())

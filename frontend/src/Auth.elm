module Auth exposing (User, onPageLoad)

import Auth.Action
import Dict
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


type alias User =
    {}


{-| Called before an auth-only page is loaded.
-}
onPageLoad : Shared.Model -> Route () -> Auth.Action.Action User
onPageLoad shared route =
    case shared.authenticated of
        Nothing ->
            Auth.Action.showLoadingPage (View.fromString "...")

        Just authed ->
            if authed then
                Auth.Action.loadPageWithUser {}

            else
                Auth.Action.pushRoute
                    { path = Route.Path.Login
                    , query = Dict.empty
                    , hash = Nothing
                    }

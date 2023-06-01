module Pages.Admin exposing (Model, Msg, page)

import Auth
import Effect exposing (Effect)
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


page : Auth.User -> Shared.Model -> Route () -> Page Model Msg
page user _ route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout (layout user)


layout : Auth.User -> Model -> Layouts.Layout
layout user model =
    Layouts.Sidebar
        { sidebar = {}
        }



-- INIT


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init _ =
    ( {}, Effect.none )



-- UPDATE


type Msg
    = Noop


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = Just <| "Admin"
    , body = []
    }

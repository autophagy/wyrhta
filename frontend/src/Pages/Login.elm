module Pages.Login exposing (Model, Msg, page)

import Api.Login exposing (login)
import Dict
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Http
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { password : String }


init : () -> ( Model, Effect Msg )
init () =
    ( { password = "" }
    , Effect.none
    )



-- UPDATE


type Msg
    = ApiRespondedLogin (Result Http.Error ())
    | PasswordUpdated String
    | Login


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        PasswordUpdated p ->
            ( { model | password = p }, Effect.none )

        Login ->
            ( model, Effect.sendCmd <| login model.password { onResponse = ApiRespondedLogin } )

        ApiRespondedLogin (Ok ()) ->
            ( model
            , Effect.batch
                [ Effect.pushRoute { path = Route.Path.Admin, query = Dict.empty, hash = Nothing }
                , Effect.auth
                ]
            )

        ApiRespondedLogin _ ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


viewLogin : Model -> Html Msg
viewLogin model =
    Html.div [ A.class "login-container" ]
        [ Html.img [ A.src "/img/logo.svg" ] []
        , Html.input [ A.type_ "password", A.name "password-name", A.value model.password, E.onInput PasswordUpdated ] []
        , Html.button [ E.onClick Login ] [ Html.text "Login" ]
        ]


view : Model -> View Msg
view model =
    { title = Just "Login"
    , body = [ viewLogin model ]
    }

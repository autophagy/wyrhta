module Pages.Works.Id_.Delete exposing (Model, Msg, page)

import Api
import Api.Work exposing (deleteWork)
import Auth
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Http
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


page : Auth.User -> Shared.Model -> Route { id : String } -> Page Model Msg
page _ _ route =
    Page.new
        { init = init route.params.id
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { id : Int
    , checkReally : Bool
    , deleteState : Maybe (Api.Data ())
    }


init : String -> () -> ( Model, Effect Msg )
init id_ _ =
    let
        id =
            Maybe.withDefault 0 <| String.toInt id_
    in
    ( { id = id, checkReally = False, deleteState = Nothing }
    , Effect.none
    )



-- UPDATE


type Msg
    = DeleteWork
    | ReallyDeleteWork
    | ApiResponededDeleteWork (Result Http.Error ())


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        DeleteWork ->
            ( { model | checkReally = True }, Effect.none )

        ReallyDeleteWork ->
            ( { model | deleteState = Just Api.Loading }
            , Effect.sendCmd <| deleteWork model.id { onResponse = ApiResponededDeleteWork }
            )

        ApiResponededDeleteWork (Ok ()) ->
            ( { model | deleteState = Just <| Api.Success (), checkReally = False }, Effect.none )

        _ ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


viewWorkDeletion : Model -> Html Msg
viewWorkDeletion model =
    let
        buttonText =
            case model.deleteState of
                Nothing ->
                    if model.checkReally then
                        "Really Delete?"

                    else
                        "Delete"

                Just (Api.Success _) ->
                    "Deleted!"

                _ ->
                    "..."
    in
    Html.div [ A.class "container" ]
        [ Html.h1 [] [ Html.text <| "Deleting Work [" ++ String.fromInt model.id ++ "]" ]
        , Html.p [] [ Html.text "This will delete all associated events with the work." ]
        , Html.button
            [ E.onClick <|
                if model.checkReally then
                    ReallyDeleteWork

                else
                    DeleteWork
            , A.classList [ ( "warning", model.checkReally ) ]
            ]
            [ Html.text buttonText ]
        ]


view : Model -> View Msg
view model =
    { title = "Deleting Work [" ++ String.fromInt model.id ++ "]"
    , body = [ viewWorkDeletion model ]
    }

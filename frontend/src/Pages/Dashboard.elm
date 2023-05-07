module Pages.Dashboard exposing (Model, Msg, page)

import Api
import Api.State exposing (State(..), stateToString)
import Api.Work exposing (Work, getWorks)
import Html exposing (Html)
import Html.Attributes exposing (class)
import Http
import Page exposing (Page)
import View exposing (View)
import Views.Posix exposing (posixToString)
import Views.String exposing (capitalize)
import Views.SummaryList exposing (Summary, summaryList)


page : Page Model Msg
page =
    Page.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { worksData : Api.Data (List Work) }


init : ( Model, Cmd Msg )
init =
    ( { worksData = Api.Loading }
    , getWorks { onResponse = ApiRespondedWorks }
    )



-- UPDATE


type Msg
    = ApiRespondedWorks (Result Http.Error (List Work))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiRespondedWorks (Ok works) ->
            ( { model | worksData = Api.Success works }
            , Cmd.none
            )

        ApiRespondedWorks (Err err) ->
            ( { model | worksData = Api.Failure err }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


workIsInProgress : Work -> Bool
workIsInProgress work =
    case work.current_state.state of
        Thrown ->
            True

        Trimming ->
            True

        _ ->
            False


workIsAwaiting : Work -> Bool
workIsAwaiting work =
    case work.current_state.state of
        AwaitingBisqueFiring ->
            True

        AwaitingGlazeFiring ->
            True

        _ ->
            False


workSummary : Work -> Summary
workSummary work =
    { thumbnail = work.images.thumbnail
    , link = "/works/" ++ String.fromInt work.id
    , title = work.name
    , summary = (capitalize <| stateToString work.current_state.state) ++ " since " ++ posixToString work.current_state.transitioned_at
    }


viewInProgressWorks : List Work -> Html Msg
viewInProgressWorks works =
    summaryList <| List.map workSummary <| List.filter workIsInProgress works


viewAwaitingWorks : List Work -> Html Msg
viewAwaitingWorks works =
    summaryList <| List.map workSummary <| List.filter workIsAwaiting works


view : Model -> View Msg
view model =
    let
        ( inProgress, awaiting ) =
            case model.worksData of
                Api.Success works ->
                    ( viewInProgressWorks works, viewAwaitingWorks works )

                _ ->
                    ( Html.div [] [], Html.div [] [] )
    in
    { title = "Pages.Dashboard"
    , body =
        [ Html.div [ class "container" ]
            [ Html.h1 [] [ Html.text "Dashboard" ]
            , Html.h2 [] [ Html.text "In Progress" ]
            , inProgress
            , Html.h2 [] [ Html.text "Awaiting" ]
            , awaiting
            ]
        ]
    }

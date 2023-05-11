module Pages.Home_ exposing (Model, Msg, page)

import Api
import Api.Event exposing (Event, getEventsWithLimit)
import Api.Project exposing (Project, getProjects)
import Api.State exposing (stateToString)
import Api.Work exposing (Work, getWork)
import Dict exposing (Dict)
import Dict.Extra exposing (groupBy)
import Html exposing (Html)
import Html.Attributes exposing (class)
import Http
import Page exposing (Page)
import View exposing (View)
import Views.LoadingPage exposing (PageState(..), viewLoadingPage)
import Views.Posix exposing (posixToString)
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


type alias EventWithWork =
    { event : Event
    , work : Work
    }


type alias Model =
    { projectData : Api.Data (List Project)
    , eventsData : List EventWithWork
    }


modelToPageState : Model -> PageState
modelToPageState model =
    case ( model.projectData, model.eventsData ) of
        ( Api.Success _, _ ) ->
            Loaded

        ( _, _ ) ->
            Loading


init : ( Model, Cmd Msg )
init =
    ( { projectData = Api.Loading, eventsData = [] }
    , Cmd.batch [ getProjects { onResponse = ApiRespondedProjects }, getEventsWithLimit 5 { onResponse = ApiRespondedEvents } ]
    )


groupEvents : List EventWithWork -> Dict String (List EventWithWork)
groupEvents events =
    groupBy (\e -> posixToString e.event.created_at) events



-- UPDATE


type Msg
    = ApiRespondedProjects (Result Http.Error (List Project))
    | ApiRespondedEvents (Result Http.Error (List Event))
    | ApiRespondedWork Event (Result Http.Error Work)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiRespondedProjects (Ok projectList) ->
            ( { model | projectData = Api.Success projectList }
            , Cmd.none
            )

        ApiRespondedProjects (Err err) ->
            ( { model | projectData = Api.Failure err }
            , Cmd.none
            )

        ApiRespondedEvents (Ok eventList) ->
            ( model
            , Cmd.batch (List.map (\event -> getWork event.work.id { onResponse = ApiRespondedWork event }) eventList)
            )

        ApiRespondedEvents (Err _) ->
            ( model, Cmd.none )

        ApiRespondedWork event (Ok work) ->
            ( { model | eventsData = EventWithWork event work :: model.eventsData }
            , Cmd.none
            )

        ApiRespondedWork _ (Err _) ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


projectSummary : Project -> Summary
projectSummary project =
    { thumbnail = project.images.thumbnail
    , link = "/projects/" ++ String.fromInt project.id
    , title = project.name
    , summary = Maybe.withDefault "" project.description
    }


viewEvent : EventWithWork -> Html Msg
viewEvent e =
    let
        event =
            e.event

        work =
            e.work

        eventStr =
            case event.previous_state of
                Just state ->
                    " transitioned from " ++ stateToString state ++ " to " ++ stateToString event.current_state ++ "."

                Nothing ->
                    " was " ++ stateToString event.current_state ++ "."
    in
    Html.div [] [ Html.a [ Html.Attributes.href ("/works/" ++ String.fromInt work.id) ] [ Html.text work.name ], Html.text eventStr ]


viewEvents : Dict String (List EventWithWork) -> List (Html Msg)
viewEvents events =
    let
        viewEventGroup =
            \date es htmlEvents -> Html.div [ class "event-block" ] [ Html.div [ class "event-date" ] [ Html.text date ], Html.div [] (List.map viewEvent es) ] :: htmlEvents
    in
    Dict.foldl viewEventGroup [] events


view : Model -> View Msg
view model =
    let
        splashView =
            Html.div [ class "splash" ] [ Html.div [ class "logo" ] [ Html.img [ Html.Attributes.src "/img/logo.svg" ] [], Html.div [ class "logo-text" ] [ Html.text "Wyrhta Ceramics" ] ] ]

        projectsView =
            case model.projectData of
                Api.Success projects ->
                    Html.div [ class "container" ] [ Html.h1 [] [ Html.text "Projects" ], summaryList <| List.map projectSummary projects ]

                _ ->
                    Html.div [] []

        eventsView =
            Html.div [ class "container" ] [ Html.h1 [] [ Html.text "Activity" ], Html.div [] (viewEvents (groupEvents model.eventsData)) ]
    in
    { title = "Wyrhta Ceramics"
    , body =
        [ splashView
        , viewLoadingPage modelToPageState model [ eventsView, projectsView ]
        ]
    }

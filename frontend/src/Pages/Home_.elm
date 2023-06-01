module Pages.Home_ exposing (Model, Msg, page)

import Api
import Api.Event exposing (Event, getEventsWithLimit)
import Api.Project exposing (Project, getProjects)
import Api.State exposing (stateToString)
import Api.Work exposing (Work, getWork)
import Dict exposing (Dict)
import Dict.Extra exposing (groupBy)
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class)
import Http
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)
import Views.Footer exposing (footer)
import Views.LoadingPage exposing (PageState(..), viewLoadingPage)
import Views.Posix exposing (posixToString)
import Views.SummaryList exposing (Summary, summaryList)


page : Shared.Model -> Route () -> Page Model Msg
page _ _ =
    Page.new
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
    , eventsData : Dict Int (Maybe EventWithWork)
    , skipEventsLoading : Bool
    }


modelToPageState : Model -> PageState
modelToPageState model =
    case ( model.projectData, model.eventsData ) of
        ( Api.Success _, events ) ->
            if (not <| hasNothing events) || model.skipEventsLoading then
                Loaded

            else
                Loading

        ( _, _ ) ->
            Loading


init : () -> ( Model, Effect Msg )
init _ =
    ( { projectData = Api.Loading, eventsData = Dict.empty, skipEventsLoading = False }
    , Effect.batchCmd [ getProjects { onResponse = ApiRespondedProjects }, getEventsWithLimit 10 { onResponse = ApiRespondedEvents } ]
    )


groupEvents : List EventWithWork -> Dict String (List EventWithWork)
groupEvents events =
    groupBy (\e -> posixToString e.event.created_at) events


hasNothing : Dict Int (Maybe EventWithWork) -> Bool
hasNothing dict =
    Dict.isEmpty dict || (Dict.values dict |> List.any (\v -> v == Nothing))


justValues : Dict Int (Maybe EventWithWork) -> List EventWithWork
justValues dict =
    Dict.values dict
        |> List.filterMap identity



-- UPDATE


type Msg
    = ApiRespondedProjects (Result Http.Error (List Project))
    | ApiRespondedEvents (Result Http.Error (List Event))
    | ApiRespondedWork Event (Result Http.Error Work)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiRespondedProjects (Ok projectList) ->
            ( { model | projectData = Api.Success projectList }
            , Effect.none
            )

        ApiRespondedProjects (Err err) ->
            ( { model | projectData = Api.Failure err }
            , Effect.none
            )

        ApiRespondedEvents (Ok eventList) ->
            ( { model | eventsData = List.map (\event -> ( event.id, Nothing )) eventList |> Dict.fromList, skipEventsLoading = List.isEmpty eventList }
            , Effect.batchCmd (List.map (\event -> getWork event.work.id { onResponse = ApiRespondedWork event }) eventList)
            )

        ApiRespondedEvents (Err _) ->
            ( model, Effect.none )

        ApiRespondedWork event (Ok work) ->
            ( { model | eventsData = Dict.insert event.id (Just <| EventWithWork event work) model.eventsData }
            , Effect.none
            )

        ApiRespondedWork _ (Err _) ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


projectSummary : Project -> Summary
projectSummary project =
    { thumbnail = project.images.thumbnail
    , path = Route.Path.Projects_Id_ { id = String.fromInt project.id }
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
    Html.div [] [ Html.a [ Route.Path.href <| Route.Path.Works_Id_ { id = String.fromInt work.id } ] [ Html.text work.name ], Html.text eventStr ]


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
            if hasNothing model.eventsData then
                Html.div [] []

            else
                Html.div [ class "container" ] [ Html.h1 [] [ Html.text "Activity" ], Html.div [] (viewEvents (groupEvents (justValues model.eventsData))) ]
    in
    { title = Nothing
    , body =
        [ splashView
        , viewLoadingPage modelToPageState model [ eventsView, projectsView ]
        , footer
        ]
    }

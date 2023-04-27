module Pages.Home_ exposing (Model, Msg, page)

import Api
import Api.Event exposing (Event, getEventsWithLimit)
import Api.Project exposing (Project, getProjects)
import Api.State as State
import Api.Work exposing (Work, getWork)
import Dict exposing (Dict)
import Dict.Extra exposing (groupBy)
import Html exposing (Html)
import Html.Attributes exposing (class)
import Http
import Page exposing (Page)
import Time exposing (Month(..), Posix, toDay, toMonth, toYear, utc)
import View exposing (View)


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


init : ( Model, Cmd Msg )
init =
    ( { projectData = Api.Loading, eventsData = [] }
    , Cmd.batch [ getProjects { onResponse = ApiRespondedProjects }, getEventsWithLimit 5 { onResponse = ApiRespondedEvents } ]
    )


groupEvents : List EventWithWork -> Dict String (List EventWithWork)
groupEvents events =
    let
        eventToString =
            \e -> String.join "." [ String.fromInt (toYear utc e.event.created_at), toMonthStr (toMonth utc e.event.created_at), String.pad 2 '0' <| String.fromInt (toDay utc e.event.created_at) ]
    in
    groupBy eventToString events



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


viewProject : Project -> Html Msg
viewProject project =
    Html.div
        [ class "project" ]
        [ Html.div [ class "project-name" ] [ Html.a [ Html.Attributes.href ("/projects/" ++ String.fromInt project.id) ] [ Html.text project.name ] ]
        , Html.div [ class "project-description" ] [ Html.text (Maybe.withDefault "" project.description) ]
        ]


stateStr s =
    case s of
        State.Thrown ->
            "thrown"

        State.Trimming ->
            "trimming"

        State.Recycled ->
            "recycled"

        State.AwaitingBisqueFiring ->
            "awaiting bisque firing"

        State.AwaitingGlazeFiring ->
            "awaiting glaze firing"

        State.Finished ->
            "finished"

        State.Unknown ->
            "unknown"


toMonthStr : Month -> String
toMonthStr month =
    case month of
        Jan ->
            "01"

        Feb ->
            "02"

        Mar ->
            "03"

        Apr ->
            "04"

        May ->
            "05"

        Jun ->
            "06"

        Jul ->
            "07"

        Aug ->
            "08"

        Sep ->
            "09"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"


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
                    " transitioned from " ++ stateStr state ++ " to " ++ stateStr event.current_state ++ "."

                Nothing ->
                    " was " ++ stateStr event.current_state ++ "."
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
            Html.div [ class "splash" ] [ Html.img [ Html.Attributes.src "/img/Logo.png" ] [] ]

        projectsView =
            case model.projectData of
                Api.Success projects ->
                    Html.div [] (List.map viewProject projects)

                Api.Loading ->
                    Html.div [] [ Html.text "..." ]

                Api.Failure _ ->
                    Html.div [] [ Html.text "Failed to load :(" ]

        eventsView =
            Html.div [] (viewEvents (groupEvents model.eventsData))
    in
    { title = "Wyrhta Ceramics"
    , body =
        [ splashView
        , Html.div [ class "container" ] [ Html.h1 [] [ Html.text "Activity" ], eventsView ]
        , Html.div [ class "container" ] [ Html.h1 [] [ Html.text "Projects" ], projectsView ]
        ]
    }

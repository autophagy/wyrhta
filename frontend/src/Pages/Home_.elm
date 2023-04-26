module Pages.Home_ exposing (Model, Msg, page)

import Api
import Api.Event exposing (Event, getEvents)
import Api.Project exposing (Project, getProjects)
import Api.State as State
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


type alias Model =
    { projectData : Api.Data (List Project)
    , eventsData : Api.Data (List Event)
    }


init : ( Model, Cmd Msg )
init =
    ( { projectData = Api.Loading, eventsData = Api.Loading }
    , Cmd.batch [ getProjects { onResponse = ApiRespondedProjects }, getEvents { onResponse = ApiRespondedEvents } ]
    )


dStr : Event -> String
dStr e =
    String.fromInt (toYear utc e.created_at)
        ++ "."
        ++ toMonthStr (toMonth utc e.created_at)
        ++ "."
        ++ String.fromInt (toDay utc e.created_at)


groupEvents : List Event -> Dict String (List Event)
groupEvents events =
    groupBy dStr events



-- UPDATE


type Msg
    = ApiRespondedProjects (Result Http.Error (List Project))
    | ApiRespondedEvents (Result Http.Error (List Event))


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
            ( { model | eventsData = Api.Success eventList }
            , Cmd.none
            )

        ApiRespondedEvents (Err err) ->
            ( { model | eventsData = Api.Failure err }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


viewProject : Project -> Html Msg
viewProject project =
    Html.div
        [ class "project" ]
        [ Html.div [ class "project-name" ] [ Html.text project.name ]
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


viewEvent : Event -> Html Msg
viewEvent event =
    let
        eventStr =
            case event.previous_state of
                Just state ->
                    "Work " ++ String.fromInt event.work.id ++ " transitioned from " ++ stateStr state ++ " to " ++ stateStr event.current_state ++ "."

                Nothing ->
                    "Work " ++ String.fromInt event.work.id ++ " was " ++ stateStr event.current_state ++ "."
    in
    Html.div [] [ Html.text eventStr ]


viewEvents : Dict String (List Event) -> List (Html Msg)
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
                Api.Loading -> Html.div [] [ Html.text "..." ]
                Api.Failure _ -> Html.div [] [ Html.text "Failed to load :(" ]


        eventsView =
            case model.eventsData of
                Api.Success events ->
                    Html.div [] (viewEvents (groupEvents (List.take 5 events)))
                Api.Loading -> Html.div [] [ Html.text "..." ]
                Api.Failure _ -> Html.div [] [ Html.text "Failed to load :(" ]

    in
    { title = "Wyrhta Ceramics"
    , body =
        [ splashView
        , Html.div [ class "container" ] [ Html.h1 [] [ Html.text "Activity" ], eventsView ]
        , Html.div [ class "container" ] [ Html.h1 [] [ Html.text "Projects" ], projectsView ]
        ]
    }

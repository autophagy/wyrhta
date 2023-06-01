module Layouts.Sidebar exposing (Model, Msg, Settings, layout)

import Api.Project exposing (Project, getProjectWorks, getProjects)
import Api.State exposing (State(..))
import Api.Work exposing (Work)
import Dict exposing (Dict)
import Dict.Extra
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Http
import Layout exposing (Layout)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


type alias Settings =
    {}


layout : Settings -> Shared.Model -> Route () -> Layout Model Msg mainMsg
layout _ shared route =
    Layout.new
        { init = init
        , update = update
        , view = view route
        , subscriptions = subscriptions
        }



-- MODEL


type alias ProjectWithWork =
    { project : Project
    , works : List Work
    , showingFinished : Bool
    }


type alias Model =
    { projects : Dict Int ProjectWithWork }


init : () -> ( Model, Effect Msg )
init _ =
    ( { projects = Dict.empty }
    , getProjects { onResponse = ApiRespondedProjects } |> Effect.sendCmd
    )



-- UPDATE


type Msg
    = ApiRespondedProjects (Result Http.Error (List Project))
    | ApiRespondedProjectWorks Project (Result Http.Error (List Work))
    | ToggleShowFinished Int


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiRespondedProjects (Ok projectList) ->
            ( model
            , Effect.batchCmd (List.map (\project -> getProjectWorks project.id { onResponse = ApiRespondedProjectWorks project }) projectList)
            )

        ApiRespondedProjectWorks project (Ok worksList) ->
            ( { model | projects = Dict.insert project.id { project = project, works = worksList, showingFinished = False } model.projects }
            , Effect.none
            )

        ToggleShowFinished id ->
            case Dict.get id model.projects of
                Just project ->
                    ( { model | projects = Dict.insert id { project | showingFinished = not project.showingFinished } model.projects }, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        _ ->
            ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view :
    Route ()
    ->
        { fromMsg : Msg -> mainMsg
        , content : View mainMsg
        , model : Model
        }
    -> View mainMsg
view route { fromMsg, model, content } =
    { title = Just "Admin"
    , body =
        [ Html.div [ A.id "admin" ]
            [ viewSidebar
                { route = route
                , model = model
                }
                |> Html.map fromMsg
            , viewMainContent content
            ]
        ]
    }


viewSidebar : { route : Route (), model : Model } -> Html Msg
viewSidebar { route, model } =
    Html.aside
        [ A.id "sidebar"
        ]
        [ viewProjects route model
        ]


viewProjects : Route a -> Model -> Html Msg
viewProjects route model =
    Html.div [ A.class "projects" ]
        [ Html.ul []
            (List.map (viewProject route) (Dict.values model.projects))
        ]


viewProject : Route a -> ProjectWithWork -> Html Msg
viewProject route project =
    let
        path =
            Route.Path.Admin_Projects_Id__Edit { id = String.fromInt project.project.id }
    in
    Html.li [ A.classList [ ( "active", route.path == path ) ] ]
        [ Html.a [ Route.Path.href path ] [ Html.text project.project.name ]
        , Html.div [ A.class "works" ] [ Html.ul [] [ viewWorks route project ] ]
        ]


viewWorks : Route a -> ProjectWithWork -> Html Msg
viewWorks route project =
    let
        inProgressWorks =
            List.filter (\w -> workCategory w == InProgress) project.works

        firingWorks =
            List.filter (\w -> workCategory w == AwaitingFiring) project.works

        finishedWorks =
            List.filter (\w -> workCategory w == Finished) project.works
    in
    Html.div []
        [ viewGroup route "In Progress" inProgressWorks
        , viewGroup route "Awaiting Firing" firingWorks
        , viewHideableGroup route "Finished Works" project.project.id project.showingFinished finishedWorks
        ]


viewGroup : Route a -> String -> List Work -> Html msg
viewGroup route group works =
    if List.length works > 0 then
        Html.div [ A.class "group" ] [ Html.div [ A.class "group-name" ] [ Html.text group ], Html.ul [] (List.map (viewWork route) works) ]

    else
        Html.div [] []


viewHideableGroup : Route a -> String -> Int -> Bool -> List Work -> Html Msg
viewHideableGroup route group id show works =
    if List.length works > 0 then
        if show then
            Html.div [ A.class "group" ] [ Html.div [ A.class "group-name", E.onClick (ToggleShowFinished id) ] [ Html.text group ], Html.ul [] (List.map (viewWork route) works) ]

        else
            Html.div [ A.class "group" ] [ Html.div [ A.class "group-name", E.onClick (ToggleShowFinished id) ] [ Html.text <| group ++ "..." ], Html.ul [] [] ]

    else
        Html.div [] []


viewWork : Route a -> Work -> Html msg
viewWork route work =
    let
        path =
            Route.Path.Admin_Works_Id__Edit { id = String.fromInt work.id }
    in
    Html.li [ A.classList [ ( "active", route.path == path ) ] ]
        [ Html.a [ Route.Path.href path ] [ Html.text work.name ]
        ]


type WorkCategory
    = InProgress
    | AwaitingFiring
    | Finished


workCategory : Work -> WorkCategory
workCategory work =
    case work.current_state.state of
        Thrown ->
            InProgress

        Trimming ->
            InProgress

        AwaitingBisqueFiring ->
            AwaitingFiring

        AwaitingGlazeFiring ->
            AwaitingFiring

        _ ->
            Finished


viewMainContent : View msg -> Html msg
viewMainContent content =
    Html.main_ []
        [ Html.div [] content.body
        ]

module Pages.Projects.Id_ exposing (Model, Msg, page)

import Api
import Api.Project exposing (Project, getProject, getProjectWorks)
import Api.State exposing (State(..))
import Api.Work exposing (Work)
import Dict
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
import Views.Posix exposing (comparePosix, posixToString)
import Views.String exposing (capitalize)
import Views.SummaryList exposing (Summary, summaryList)


page : Shared.Model -> Route { id : String } -> Page Model Msg
page model route =
    Page.new
        { init = init route.params.id
        , update = update
        , subscriptions = subscriptions
        , view = view route.params.id
        }



-- INIT


type alias Model =
    { projectData : Api.Data Project
    , projectWorksData : Api.Data (List Work)
    }


modelToPageState : Model -> PageState
modelToPageState model =
    case ( model.projectData, model.projectWorksData ) of
        ( Api.Success _, Api.Success _ ) ->
            Loaded

        ( _, _ ) ->
            Loading


init : String -> () -> ( Model, Effect Msg )
init id _ =
    ( { projectData = Api.Loading, projectWorksData = Api.Loading }
    , Effect.batchCmd
        [ getProject (Maybe.withDefault 0 (String.toInt id)) { onResponse = ApiRespondedProject }
        , getProjectWorks (Maybe.withDefault 0 (String.toInt id)) { onResponse = ApiRespondedWorks }
        ]
    )



-- UPDATE


type Msg
    = ApiRespondedProject (Result Http.Error Project)
    | ApiRespondedWorks (Result Http.Error (List Work))


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiRespondedProject (Ok project) ->
            ( { model | projectData = Api.Success project }
            , Effect.none
            )

        ApiRespondedProject (Err (Http.BadStatus 404)) ->
            ( { model | projectData = Api.Failure (Http.BadStatus 404) }
            , Effect.pushRoute { path = Route.Path.NotFound_, query = Dict.empty, hash = Nothing }
            )

        ApiRespondedProject (Err err) ->
            ( { model | projectData = Api.Failure err }
            , Effect.none
            )

        ApiRespondedWorks (Ok works) ->
            ( { model | projectWorksData = Api.Success works }
            , Effect.none
            )

        ApiRespondedWorks (Err err) ->
            ( { model | projectWorksData = Api.Failure err }
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


viewProject : Project -> Html Msg
viewProject project =
    Html.div []
        [ Html.div [ class "container project-name" ]
            [ Html.h1 [] [ Html.text project.name ]
            , Html.div [] [ Html.text <| Maybe.withDefault "" project.description ]
            ]
        ]


stateToString : State -> String
stateToString state =
    case state of
        Thrown ->
            "thrown"

        Trimming ->
            "in trimming"

        AwaitingBisqueFiring ->
            "awaiting bisque firing"

        AwaitingGlazeFiring ->
            "awaiting glaze firing"

        Finished ->
            "finished"

        Recycled ->
            "recycled"

        _ ->
            "unknown"


workSummary : Work -> Summary
workSummary work =
    { thumbnail = work.images.thumbnail
    , path = Route.Path.Works_Id_ { id = String.fromInt work.id }
    , title = work.name
    , summary = (capitalize <| stateToString work.current_state.state) ++ " since " ++ posixToString work.current_state.transitioned_at
    }


viewWorks : List Work -> Html Msg
viewWorks works =
    Html.div [ class "container" ]
        [ summaryList <|
            List.map workSummary <|
                List.sortWith (\a b -> comparePosix b.current_state.transitioned_at a.current_state.transitioned_at) works
        ]


view : String -> Model -> View Msg
view id model =
    let
        title =
            case model.projectData of
                Api.Success project ->
                    Just project.name

                _ ->
                    Nothing

        projectView =
            case model.projectData of
                Api.Success project ->
                    viewProject project

                _ ->
                    Html.div [] []

        worksView =
            case model.projectWorksData of
                Api.Success works ->
                    viewWorks works

                _ ->
                    Html.div [] []
    in
    { title = title
    , body = [ viewLoadingPage modelToPageState model [ projectView, worksView ], footer ]
    }

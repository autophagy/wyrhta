module Pages.Projects.Id_ exposing (Model, Msg, page)

import Api
import Api.Project exposing (Project, getProject, getProjectWorks)
import Api.State exposing (State(..))
import Api.Work exposing (Work)
import Html exposing (Html)
import Html.Attributes exposing (class)
import Http
import Page exposing (Page)
import View exposing (View)
import Views.LoadingPage exposing (PageState(..), viewLoadingPage)
import Views.Posix exposing (posixToString)
import Views.String exposing (capitalize)
import Views.SummaryList exposing (Summary, summaryList)


page : { id : String } -> Page Model Msg
page params =
    Page.element
        { init = init params.id
        , update = update
        , subscriptions = subscriptions
        , view = view params.id
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


init : String -> ( Model, Cmd Msg )
init id =
    ( { projectData = Api.Loading, projectWorksData = Api.Loading }
    , Cmd.batch
        [ getProject (Maybe.withDefault 0 (String.toInt id)) { onResponse = ApiRespondedProject }
        , getProjectWorks (Maybe.withDefault 0 (String.toInt id)) { onResponse = ApiRespondedWorks }
        ]
    )



-- UPDATE


type Msg
    = ApiRespondedProject (Result Http.Error Project)
    | ApiRespondedWorks (Result Http.Error (List Work))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiRespondedProject (Ok project) ->
            ( { model | projectData = Api.Success project }
            , Cmd.none
            )

        ApiRespondedProject (Err err) ->
            ( { model | projectData = Api.Failure err }
            , Cmd.none
            )

        ApiRespondedWorks (Ok works) ->
            ( { model | projectWorksData = Api.Success works }
            , Cmd.none
            )

        ApiRespondedWorks (Err err) ->
            ( { model | projectWorksData = Api.Failure err }
            , Cmd.none
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
    , link = "/works/" ++ String.fromInt work.id
    , title = work.name
    , summary = (capitalize <| stateToString work.current_state.state) ++ " since " ++ posixToString work.current_state.transitioned_at
    }


viewWorks : List Work -> Html Msg
viewWorks works =
    Html.div [ class "container" ] [ summaryList <| List.map workSummary works ]


view : String -> Model -> View Msg
view id model =
    let
        title =
            case model.projectData of
                Api.Success project ->
                    project.name

                _ ->
                    ""

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

        controls =
            Html.div [ class "controls container" ]
                [ Html.a [ Html.Attributes.href <| "/projects/" ++ id ++ "/edit" ] [ Html.text "Edit" ] ]
    in
    { title = title
    , body = [ viewLoadingPage modelToPageState model [ projectView, worksView ], controls ]
    }

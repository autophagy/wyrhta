module Pages.Projects.Id_.Edit exposing (Model, Msg, page)

import Api
import Api.Project exposing (Project, UpdateProject, getProject, putProject)
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Http
import Page exposing (Page)
import View exposing (View)


page : { id : String } -> Page Model Msg
page params =
    Page.element
        { init = init params.id
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { projectData : Api.Data Project
    , id : Int
    , projectName : String
    , projectDescription : Maybe String
    , updateState : Maybe (Api.Data ())
    }


init : String -> ( Model, Cmd Msg )
init id_ =
    let
        id =
            Maybe.withDefault 0 <| String.toInt id_
    in
    ( { projectData = Api.Loading, id = id, projectName = "", projectDescription = Nothing, updateState = Nothing }
    , getProject id { onResponse = ApiRespondedProject }
    )



-- UPDATE


type Msg
    = ApiRespondedProject (Result Http.Error Project)
    | ApiRespondedUpdateProject (Result Http.Error ())
    | ProjectNameUpdated String
    | UpdateProject
    | ProjectDescriptionUpdated String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiRespondedProject (Ok project) ->
            ( { model | projectData = Api.Success project, projectName = project.name, projectDescription = project.description }
            , Cmd.none
            )

        ProjectNameUpdated s ->
            ( { model | projectName = s }, Cmd.none )

        ProjectDescriptionUpdated s ->
            let
                description =
                    case s of
                        "" ->
                            Nothing

                        str ->
                            Just str
            in
            ( { model | projectDescription = description }, Cmd.none )

        UpdateProject ->
            ( { model | updateState = Just Api.Loading }, putProject model.id { name = model.projectName, description = model.projectDescription } { onResponse = ApiRespondedUpdateProject } )

        ApiRespondedUpdateProject (Ok ()) ->
            ( { model | updateState = Just <| Api.Success () }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


viewProjectDetails : Model -> Html Msg
viewProjectDetails model =
    let
        buttonText =
            case model.updateState of
                Nothing ->
                    "Update"

                Just (Api.Success _) ->
                    "Updated!"

                _ ->
                    "..."
    in
    Html.div [ A.class "container" ]
        [ Html.h2 [] [ Html.text "Name" ]
        , Html.input [ A.type_ "text", A.name "project-name", A.value model.projectName, E.onInput ProjectNameUpdated ] []
        , Html.h2 [] [ Html.text "Description" ]
        , Html.textarea [ A.name "project-description", A.value <| Maybe.withDefault "" model.projectDescription, E.onInput ProjectDescriptionUpdated ] []
        , Html.button [ E.onClick UpdateProject ] [ Html.text buttonText ]
        ]


view : Model -> View Msg
view model =
    { title = "Pages.Projects.Id_.Edit"
    , body = [ viewProjectDetails model ]
    }

module Pages.Projects.Create exposing (Model, Msg, page)

import Api
import Api.Project exposing (Project, UpdateProject, getProject, postProject, putProject)
import Api.Upload exposing (upload)
import File exposing (File)
import File.Select as Select
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Http
import Page exposing (Page)
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
    { projectName : String
    , projectDescription : Maybe String
    , projectThumbnail : Maybe String
    , createState : Maybe (Api.Data ())
    }


init : ( Model, Cmd Msg )
init =
    ( { projectName = "", projectDescription = Nothing, projectThumbnail = Nothing, createState = Nothing }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ProjectNameUpdated String
    | ProjectDescriptionUpdated String
    | SelectdNewThumbnailUpload
    | SelectedThumbnail File
    | UploadedNewThumbnail (Result Http.Error String)
    | CreateProject
    | ApiRespondedCreateProject (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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

        CreateProject ->
            ( { model | createState = Just Api.Loading }, postProject { name = model.projectName, description = model.projectDescription, thumbnail = model.projectThumbnail } { onResponse = ApiRespondedCreateProject } )

        ApiRespondedCreateProject (Ok ()) ->
            ( { model | createState = Just <| Api.Success () }, Cmd.none )

        SelectdNewThumbnailUpload ->
            ( model, Select.file [ "image/*" ] SelectedThumbnail )

        SelectedThumbnail image ->
            ( model, upload image "projects/thumbnails" { onResponse = UploadedNewThumbnail } )

        UploadedNewThumbnail (Ok url) ->
            ( { model | projectThumbnail = Just url }, Cmd.none )

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
            case model.createState of
                Nothing ->
                    "Create"

                Just (Api.Success _) ->
                    "Created!"

                _ ->
                    "..."
    in
    Html.div [ A.class "container" ]
        [ Html.h1 [] [ Html.text "Creating New Project" ]
        , Html.div [ A.class "settings project-settings" ]
            [ Html.div [ A.class "left" ]
                [ Html.h2 [] [ Html.text "Name" ]
                , Html.input [ A.type_ "text", A.name "project-name", A.value model.projectName, E.onInput ProjectNameUpdated ] []
                , Html.h2 [] [ Html.text "Description" ]
                , Html.textarea [ A.name "project-description", A.value <| Maybe.withDefault "" model.projectDescription, E.onInput ProjectDescriptionUpdated ] []
                ]
            , Html.div [ A.class "right" ]
                [ Html.h2 [] [ Html.text "Thumbnail" ]
                , Html.img [ A.class "image-upload thumbnail", A.src <| Maybe.withDefault "/img/placeholder-thumbnail.jpg" model.projectThumbnail, E.onClick SelectdNewThumbnailUpload ] []
                ]
            ]
        , Html.button [ E.onClick CreateProject ] [ Html.text buttonText ]
        ]


view : Model -> View Msg
view model =
    { title = "Creating New Project"
    , body = [ viewProjectDetails model ]
    }

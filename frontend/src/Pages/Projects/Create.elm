module Pages.Projects.Create exposing (Model, Msg, page)

import Api
import Api.Project exposing (postProject)
import Api.Upload exposing (upload)
import Auth
import Dict
import Effect exposing (Effect)
import File exposing (File)
import File.Select as Select
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Http
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


page : Auth.User -> Shared.Model -> Route () -> Page Model Msg
page _ _ _ =
    Page.new
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


init : () -> ( Model, Effect Msg )
init () =
    ( { projectName = "", projectDescription = Nothing, projectThumbnail = Nothing, createState = Nothing }
    , Effect.none
    )



-- UPDATE


type Msg
    = ProjectNameUpdated String
    | ProjectDescriptionUpdated String
    | SelectdNewThumbnailUpload
    | SelectedThumbnail File
    | UploadedNewThumbnail (Result Http.Error String)
    | CreateProject
    | ApiRespondedCreateProject (Result Http.Error Int)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ProjectNameUpdated s ->
            ( { model | projectName = s }, Effect.none )

        ProjectDescriptionUpdated s ->
            let
                description =
                    case s of
                        "" ->
                            Nothing

                        str ->
                            Just str
            in
            ( { model | projectDescription = description }, Effect.none )

        CreateProject ->
            ( { model | createState = Just Api.Loading }, Effect.sendCmd <| postProject { name = model.projectName, description = model.projectDescription, thumbnail = model.projectThumbnail } { onResponse = ApiRespondedCreateProject } )

        ApiRespondedCreateProject (Ok id) ->
            ( { model | createState = Just <| Api.Success () }
            , Effect.pushRoute { path = Route.Path.Projects_Id_ { id = String.fromInt id }, query = Dict.empty, hash = Nothing }
            )

        SelectdNewThumbnailUpload ->
            ( model, Effect.sendCmd <| Select.file [ "image/*" ] SelectedThumbnail )

        SelectedThumbnail image ->
            ( model, Effect.sendCmd <| upload image "projects/thumbnails" { onResponse = UploadedNewThumbnail } )

        UploadedNewThumbnail (Ok url) ->
            ( { model | projectThumbnail = Just url }, Effect.none )

        _ ->
            ( model, Effect.none )



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

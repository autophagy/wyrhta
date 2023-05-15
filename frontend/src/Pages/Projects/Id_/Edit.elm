module Pages.Projects.Id_.Edit exposing (Model, Msg, page)

import Api
import Api.Project exposing (Project, UpdateProject, getProject, putProject)
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


page : Auth.User -> Shared.Model -> Route { id : String } -> Page Model Msg
page _ _ route =
    Page.new
        { init = init route.params.id
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
    , projectThumbnail : Maybe String
    , updateState : Maybe (Api.Data ())
    }


init : String -> () -> ( Model, Effect Msg )
init id_ _ =
    let
        id =
            Maybe.withDefault 0 <| String.toInt id_
    in
    ( { projectData = Api.Loading, id = id, projectName = "", projectDescription = Nothing, projectThumbnail = Nothing, updateState = Nothing }
    , Effect.sendCmd <| getProject id { onResponse = ApiRespondedProject }
    )



-- UPDATE


type Msg
    = ApiRespondedProject (Result Http.Error Project)
    | ApiRespondedUpdateProject (Result Http.Error ())
    | ProjectNameUpdated String
    | SelectdNewThumbnailUpload
    | SelectedThumbnail File
    | UploadedNewThumbnail (Result Http.Error String)
    | UpdateProject
    | ProjectDescriptionUpdated String


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiRespondedProject (Ok project) ->
            ( { model | projectData = Api.Success project, projectName = project.name, projectDescription = project.description, projectThumbnail = project.images.thumbnail }
            , Effect.none
            )

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

        UpdateProject ->
            ( { model | updateState = Just Api.Loading }
            , Effect.sendCmd <|
                putProject model.id
                    { name = model.projectName
                    , description = model.projectDescription
                    , thumbnail = model.projectThumbnail
                    }
                    { onResponse = ApiRespondedUpdateProject }
            )

        ApiRespondedUpdateProject (Ok ()) ->
            ( { model | updateState = Just <| Api.Success () }
            , Effect.pushRoute { path = Route.Path.Projects_Id_ { id = String.fromInt model.id }, query = Dict.empty, hash = Nothing }
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
            case model.updateState of
                Nothing ->
                    "Update"

                Just (Api.Success _) ->
                    "Updated!"

                _ ->
                    "..."
    in
    Html.div [ A.class "container" ]
        [ Html.h1 [] [ Html.text <| "Editing Project [" ++ String.fromInt model.id ++ "]" ]
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
        , Html.button [ E.onClick UpdateProject ] [ Html.text buttonText ]
        ]


view : Model -> View Msg
view model =
    { title = "Editing Project [" ++ String.fromInt model.id ++ "]"
    , body = [ viewProjectDetails model ]
    }

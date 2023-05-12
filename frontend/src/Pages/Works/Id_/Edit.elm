module Pages.Works.Id_.Edit exposing (Model, Msg, page)

import Api
import Api.Clay exposing (Clay, getClays)
import Api.Project exposing (Project, getProjects)
import Api.Upload exposing (upload)
import Api.Work exposing (UpdateWork, Work, getWork, putWork)
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


page : Shared.Model -> Route { id : String } -> Page Model Msg
page _ route =
    Page.new
        { init = init route.params.id
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { projectData : Api.Data (List Project)
    , clayData : Api.Data (List Clay)
    , workData : Api.Data Work
    , id : Int
    , projectId : Int
    , name : String
    , notes : Maybe String
    , clayId : Int
    , glazeDescription : Maybe String
    , thumbnail : Maybe String
    , header : Maybe String
    , updateState : Maybe (Api.Data ())
    }


init : String -> () -> ( Model, Effect Msg )
init id_ _ =
    let
        id =
            Maybe.withDefault 0 <| String.toInt id_
    in
    ( { projectData = Api.Loading
      , clayData = Api.Loading
      , workData = Api.Loading
      , id = id
      , projectId = 0
      , name = ""
      , notes = Nothing
      , clayId = 0
      , glazeDescription = Nothing
      , updateState = Nothing
      , thumbnail = Nothing
      , header = Nothing
      }
    , Effect.batch <|
        List.map Effect.sendCmd
            [ getProjects { onResponse = ApiRespondedProjects }
            , getClays { onResponse = ApiRespondedClays }
            , getWork id { onResponse = ApiRespondedWork }
            ]
    )



-- UPDATE


type Msg
    = ApiRespondedProjects (Result Http.Error (List Project))
    | ApiRespondedClays (Result Http.Error (List Clay))
    | ApiRespondedWork (Result Http.Error Work)
    | ProjectIdUpdated String
    | NameUpdated String
    | NotesUpdated String
    | ClayIdUpdated String
    | GlazeDescriptionUpdated String
    | UpdateWork
    | SelectNewThumbnailUpload
    | SelectedThumbnail File
    | UploadedNewThumbnail (Result Http.Error String)
    | SelectNewHeaderUpload
    | SelectedHeader File
    | UploadedNewHeader (Result Http.Error String)
    | ApiResponededUpdateWork (Result Http.Error ())


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiRespondedProjects (Ok projects) ->
            ( { model | projectData = Api.Success projects }
            , Effect.none
            )

        ApiRespondedClays (Ok clays) ->
            ( { model | clayData = Api.Success clays }
            , Effect.none
            )

        ApiRespondedWork (Ok work) ->
            ( { model | workData = Api.Success work, id = work.id, projectId = work.project.id, name = work.name, notes = work.notes, clayId = work.clay.id, glazeDescription = work.glaze_description, thumbnail = work.images.thumbnail, header = work.images.header }
            , Effect.none
            )

        ProjectIdUpdated id ->
            ( { model | projectId = Maybe.withDefault 0 <| String.toInt id }
            , Effect.none
            )

        NameUpdated name ->
            ( { model | name = name }
            , Effect.none
            )

        NotesUpdated n ->
            let
                notes =
                    case n of
                        "" ->
                            Nothing

                        str ->
                            Just str
            in
            ( { model | notes = notes }, Effect.none )

        ClayIdUpdated id ->
            ( { model | clayId = Maybe.withDefault 0 <| String.toInt id }
            , Effect.none
            )

        GlazeDescriptionUpdated d ->
            let
                desc =
                    case d of
                        "" ->
                            Nothing

                        str ->
                            Just str
            in
            ( { model | glazeDescription = desc }
            , Effect.none
            )

        SelectNewHeaderUpload ->
            ( model, Effect.sendCmd <| Select.file [ "image/*" ] SelectedHeader )

        SelectedHeader image ->
            ( model, Effect.sendCmd <| upload image "works/headers" { onResponse = UploadedNewHeader } )

        UploadedNewHeader (Ok url) ->
            ( { model | header = Just url }, Effect.none )

        SelectNewThumbnailUpload ->
            ( model, Effect.sendCmd <| Select.file [ "image/*" ] SelectedThumbnail )

        SelectedThumbnail image ->
            ( model, Effect.sendCmd <| upload image "works/thumbnails" { onResponse = UploadedNewThumbnail } )

        UploadedNewThumbnail (Ok url) ->
            ( { model | thumbnail = Just url }, Effect.none )

        UpdateWork ->
            ( { model | updateState = Just Api.Loading }
            , Effect.sendCmd <|
                putWork model.id
                    { project_id = model.projectId
                    , name = model.name
                    , notes = model.notes
                    , clay_id = model.clayId
                    , glaze_description = model.glazeDescription
                    , thumbnail = model.thumbnail
                    , header = model.header
                    }
                    { onResponse = ApiResponededUpdateWork }
            )

        ApiResponededUpdateWork (Ok ()) ->
            ( { model | updateState = Just <| Api.Success () }
            , Effect.pushRoute
                { path = Route.Path.Works_Id_ { id = String.fromInt model.id }
                , query = Dict.empty
                , hash = Nothing
                }
            )

        _ ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


projectToOption : String -> Project -> Html Msg
projectToOption selected project =
    Html.option [ A.value <| String.fromInt project.id, A.selected (selected == String.fromInt project.id) ] [ Html.text project.name ]


viewProjects : Model -> Html Msg
viewProjects model =
    let
        projects =
            case model.projectData of
                Api.Success p ->
                    p

                _ ->
                    []
    in
    Html.select [ E.onInput ProjectIdUpdated ] (List.map (projectToOption <| String.fromInt model.projectId) projects)


clayToOption : String -> Clay -> Html Msg
clayToOption selected clay =
    let
        isSelected =
            selected == String.fromInt clay.id
    in
    Html.option [ A.value <| String.fromInt clay.id, A.selected isSelected ] [ Html.text clay.name ]


viewClays : Model -> Html Msg
viewClays model =
    let
        clays =
            case model.clayData of
                Api.Success c ->
                    c

                _ ->
                    []
    in
    Html.select [ E.onInput ClayIdUpdated ] (List.map (clayToOption <| String.fromInt model.clayId) clays)


viewWorkDetails : Model -> Html Msg
viewWorkDetails model =
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
        [ Html.h1 [] [ Html.text <| "Editing Work [" ++ String.fromInt model.id ++ "]" ]
        , Html.div [ A.class "settings work-settings" ]
            [ Html.div [ A.class "left" ]
                [ Html.h2 [] [ Html.text "Project" ]
                , viewProjects model
                , Html.h2 [] [ Html.text "Name" ]
                , Html.input [ A.type_ "text", A.name "work-name", A.value model.name, E.onInput NameUpdated ] []
                , Html.h2 [] [ Html.text "Notes" ]
                , Html.textarea [ A.name "work-notes", A.value <| Maybe.withDefault "" model.notes, E.onInput NotesUpdated ] []
                , Html.h2 [] [ Html.text "Clay Body" ]
                , viewClays model
                , Html.h2 [] [ Html.text "Glaze Description" ]
                , Html.input [ A.type_ "text", A.name "work-name", A.value <| Maybe.withDefault "" model.glazeDescription, E.onInput GlazeDescriptionUpdated ] []
                ]
            , Html.div [ A.class "right" ]
                [ Html.h2 [] [ Html.text "Header" ]
                , Html.img [ A.class "image-upload header", A.src <| Maybe.withDefault "/img/placeholder-thumbnail.jpg" model.header, E.onClick SelectNewHeaderUpload ] []
                , Html.h2 [] [ Html.text "Thumbnail" ]
                , Html.img [ A.class "image-upload thumbnail", A.src <| Maybe.withDefault "/img/placeholder-thumbnail.jpg" model.thumbnail, E.onClick SelectNewThumbnailUpload ] []
                ]
            ]
        , Html.button [ E.onClick UpdateWork ] [ Html.text buttonText ]
        ]


view : Model -> View Msg
view model =
    { title = "Editing Project [" ++ String.fromInt model.id ++ "]"
    , body = [ viewWorkDetails model ]
    }

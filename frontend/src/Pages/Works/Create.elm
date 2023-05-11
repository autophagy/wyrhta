module Pages.Works.Create exposing (Model, Msg, page)

import Api
import Api.Clay exposing (Clay, getClays)
import Api.Project exposing (Project, getProjects)
import Api.Upload exposing (upload)
import Api.Work exposing (postWork)
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
    { projectData : Api.Data (List Project)
    , clayData : Api.Data (List Clay)
    , projectId : Int
    , name : String
    , notes : Maybe String
    , clayId : Int
    , glazeDescription : Maybe String
    , thumbnail : Maybe String
    , header : Maybe String
    , updateState : Maybe (Api.Data ())
    }


init : ( Model, Cmd Msg )
init =
    ( { projectData = Api.Loading
      , clayData = Api.Loading
      , projectId = 0
      , name = ""
      , notes = Nothing
      , clayId = 0
      , glazeDescription = Nothing
      , updateState = Nothing
      , thumbnail = Nothing
      , header = Nothing
      }
    , Cmd.batch
        [ getProjects { onResponse = ApiRespondedProjects }
        , getClays { onResponse = ApiRespondedClays }
        ]
    )



-- UPDATE


type Msg
    = ApiRespondedProjects (Result Http.Error (List Project))
    | ApiRespondedClays (Result Http.Error (List Clay))
    | ProjectIdUpdated String
    | NameUpdated String
    | NotesUpdated String
    | ClayIdUpdated String
    | GlazeDescriptionUpdated String
    | SelectNewThumbnailUpload
    | SelectedThumbnail File
    | UploadedNewThumbnail (Result Http.Error String)
    | SelectNewHeaderUpload
    | SelectedHeader File
    | UploadedNewHeader (Result Http.Error String)
    | CreateWork
    | ApiResponededCreateWork (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiRespondedProjects (Ok projects) ->
            ( { model | projectData = Api.Success projects, projectId = Maybe.withDefault 0 <| Maybe.map (.id) <| List.head projects }
            , Cmd.none
            )

        ApiRespondedClays (Ok clays) ->
            ( { model | clayData = Api.Success clays, clayId = Maybe.withDefault 0 <| Maybe.map (.id) <| List.head clays }
            , Cmd.none
            )

        ProjectIdUpdated id ->
            ( { model | projectId = Maybe.withDefault 0 <| String.toInt id }
            , Cmd.none
            )

        NameUpdated name ->
            ( { model | name = name }
            , Cmd.none
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
            ( { model | notes = notes }, Cmd.none )

        ClayIdUpdated id ->
            ( { model | clayId = Maybe.withDefault 0 <| String.toInt id }
            , Cmd.none
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
            , Cmd.none
            )

        SelectNewHeaderUpload ->
            ( model, Select.file [ "image/*" ] SelectedHeader )

        SelectedHeader image ->
            ( model, upload image "works/headers" { onResponse = UploadedNewHeader } )

        UploadedNewHeader (Ok url) ->
            ( { model | header = Just url }, Cmd.none )

        SelectNewThumbnailUpload ->
            ( model, Select.file [ "image/*" ] SelectedThumbnail )

        SelectedThumbnail image ->
            ( model, upload image "works/thumbnails" { onResponse = UploadedNewThumbnail } )

        UploadedNewThumbnail (Ok url) ->
            ( { model | thumbnail = Just url }, Cmd.none )

        CreateWork ->
            ( { model | updateState = Just Api.Loading }
            , postWork { project_id = model.projectId, name = model.name, notes = model.notes, clay_id = model.clayId, glaze_description = model.glazeDescription, thumbnail = model.thumbnail, header = model.header } { onResponse = ApiResponededCreateWork }
            )

        ApiResponededCreateWork (Ok ()) ->
            ( { model | updateState = Just <| Api.Success () }, Cmd.none )

        _ ->
            ( model, Cmd.none )



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
                    "Create"

                Just (Api.Success _) ->
                    "Created!"

                _ ->
                    "..."
    in
    Html.div [ A.class "container" ]
        [ Html.h1 [] [ Html.text "Creating New Work" ]
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
        , Html.button [ E.onClick CreateWork ] [ Html.text buttonText ]
        ]


view : Model -> View Msg
view model =
    { title = "Creating New Work"
    , body = [ viewWorkDetails model ]
    }
